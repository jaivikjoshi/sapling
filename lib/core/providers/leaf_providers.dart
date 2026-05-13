import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data/db/leko_database.dart';
import '../../features/leaf/leaf_action_executor.dart';
import '../../features/leaf/leaf_assistant_responses.dart';
import '../../features/leaf/leaf_assistant_service.dart';
import '../../features/leaf/leaf_context.dart';
import '../../features/leaf/leaf_models.dart';
import 'allowance_providers.dart';
import 'auth_providers.dart';
import 'bills_providers.dart';
import 'goals_providers.dart';
import 'ledger_providers.dart';
import 'profile_providers.dart';
import 'settings_providers.dart';

final leafContextProvider = Provider<LeafContext>((ref) {
  final user = ref.watch(currentUserProvider);
  final profile = ref.watch(profileServiceProvider);
  final name = profile.firstName(user).trim();
  final greeting = name.isEmpty ? profile.displayName(user).trim() : name;

  final settings = ref.watch(settingsStreamProvider).valueOrNull;
  final balance = ref.watch(balanceStreamProvider).valueOrNull;
  final mode = ref.watch(effectiveAllowanceModeProvider);
  final paycheck = ref.watch(paycheckAllowanceProvider).valueOrNull;
  final goal = ref.watch(goalAllowanceProvider).valueOrNull;
  final goals = ref.watch(goalsStreamProvider).valueOrNull ?? const <Goal>[];
  final bills = ref.watch(upcomingBillsProvider).valueOrNull ?? const <Bill>[];
  final txns =
      ref.watch(recentTransactionsProvider).valueOrNull ?? const <Transaction>[];

  Goal? primary;
  final pid = settings?.primaryGoalId;
  if (pid != null) {
    for (final g in goals) {
      if (g.id == pid) {
        primary = g;
        break;
      }
    }
  }

  final sortedBills = [...bills]
    ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  final recent = txns.take(5).toList();

  return LeafContext(
    greetingName: greeting,
    allowanceMode: mode,
    settings: settings,
    balance: balance,
    paycheck: paycheck,
    goal: goal,
    primaryGoal: primary,
    upcomingBills: sortedBills,
    recentTransactions: recent,
  );
});

class LeafChatMessage {
  const LeafChatMessage({
    required this.isUser,
    required this.text,
    required this.at,
    this.kind = LeafMessageKind.text,
    this.action,
    this.success,
    this.clarificationField,
    this.clarificationOptions = const [],
    this.attachments = const [],
  });

  final bool isUser;
  final String text;
  final DateTime at;
  final LeafMessageKind kind;
  final LeafPendingAction? action;
  final bool? success;

  /// Present on clarification messages. When the user taps an option from
  /// [clarificationOptions], its `patch` is merged into [action].data.
  final String? clarificationField;
  final List<LeafClarificationOption> clarificationOptions;

  /// Metadata about user-attached files so they appear inline in the chat.
  final List<LeafAttachmentPreview> attachments;

  LeafChatMessage withClarificationCleared() {
    return LeafChatMessage(
      isUser: isUser,
      text: text,
      at: at,
      kind: kind,
      action: action,
      success: success,
      clarificationField: null,
      clarificationOptions: const [],
      attachments: attachments,
    );
  }
}

/// UI-facing preview of a user-attached file; we deliberately do not keep
/// the raw base64 payload on the chat message after sending so memory
/// footprint stays bounded.
class LeafAttachmentPreview {
  const LeafAttachmentPreview({required this.name, required this.mime});

  final String name;
  final String mime;

  bool get isImage => mime.startsWith('image/');
  bool get isPdf => mime == 'application/pdf';
}

enum LeafMessageKind {
  text,
  clarification,
  actionPreview,
  executionResult,
  error,
}

const _leafNoChange = Object();

class LeafConversationState {
  const LeafConversationState({
    this.messages = const [],
    this.pendingAction,
    this.isLoading = false,
    this.error,
    this.suggestedPrompts = _defaultLeafPrompts,
    this.stagedAttachments = const [],
  });

  final List<LeafChatMessage> messages;
  final LeafPendingAction? pendingAction;
  final bool isLoading;
  final String? error;
  final List<String> suggestedPrompts;

  /// Attachments the user has added to the composer but hasn't sent yet.
  final List<LeafAttachment> stagedAttachments;

  LeafConversationState copyWith({
    List<LeafChatMessage>? messages,
    Object? pendingAction = _leafNoChange,
    bool? isLoading,
    Object? error = _leafNoChange,
    List<String>? suggestedPrompts,
    List<LeafAttachment>? stagedAttachments,
  }) {
    return LeafConversationState(
      messages: messages ?? this.messages,
      pendingAction: pendingAction == _leafNoChange
          ? this.pendingAction
          : pendingAction as LeafPendingAction?,
      isLoading: isLoading ?? this.isLoading,
      error: error == _leafNoChange ? this.error : error as String?,
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
      stagedAttachments: stagedAttachments ?? this.stagedAttachments,
    );
  }
}

const List<String> _defaultLeafPrompts = <String>[
  'How much can I spend today?',
  'What bills are coming up?',
  'Give me a budgeting tip',
  r'Add my $25 dinner',
];

class LeafConversationController extends StateNotifier<LeafConversationState> {
  LeafConversationController(this.ref)
      : super(
          LeafConversationState(
            messages: [
              LeafChatMessage(
                isUser: false,
                text:
                    "I'm Leko. Ask me for a budgeting tip, a read on your week, or tell me something to record and I'll preview it before anything changes.",
                at: DateTime.now(),
              ),
            ],
          ),
        );

  final Ref ref;

  /// Prevents overlapping [confirmPendingAction] runs (e.g. double-tap on
  /// Confirm) from inserting duplicate ledger rows before the first await.
  bool _confirmPendingInFlight = false;

  LeafContext get _ctx => ref.read(leafContextProvider);
  List<Category> get _categories =>
      ref.read(categoriesProvider).valueOrNull ?? const <Category>[];
  List<Goal> get _goals =>
      ref.read(goalsStreamProvider).valueOrNull ?? const <Goal>[];
  List<Bill> get _bills =>
      ref.read(billsStreamProvider).valueOrNull ?? const <Bill>[];
  LeafAssistantService get _assistant =>
      ref.read(leafAssistantServiceProvider);
  LeafActionExecutor get _executor => ref.read(leafActionExecutorProvider);

  void clearConversation() {
    _confirmPendingInFlight = false;
    state = LeafConversationState(
      messages: [
        LeafChatMessage(
          isUser: false,
          text:
              "Fresh thread. Ask about spending, bills, goals, or tell me what you want to log.",
          at: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> askKind(LeafQueryKind kind) {
    final label = switch (kind) {
      LeafQueryKind.spendingToday => 'Spending today',
      LeafQueryKind.bills => 'Bills',
      LeafQueryKind.goal => 'My goal',
      LeafQueryKind.thisCycle => 'This cycle',
    };
    return submitFreeText(label);
  }

  void addStagedAttachment(LeafAttachment attachment) {
    if (state.stagedAttachments.length >= 3) return;
    state = state.copyWith(
      stagedAttachments: [...state.stagedAttachments, attachment],
    );
  }

  void removeStagedAttachmentAt(int index) {
    if (index < 0 || index >= state.stagedAttachments.length) return;
    final next = [...state.stagedAttachments]..removeAt(index);
    state = state.copyWith(stagedAttachments: next);
  }

  void clearStagedAttachments() {
    if (state.stagedAttachments.isEmpty) return;
    state = state.copyWith(stagedAttachments: const []);
  }

  Future<void> submitFreeText(String raw) async {
    final trimmed = raw.trim();
    final attachments = state.stagedAttachments;
    if (trimmed.isEmpty && attachments.isEmpty) return;

    final now = DateTime.now();
    final userText = trimmed.isEmpty ? _attachmentSummaryText(attachments) : trimmed;
    final userMessage = LeafChatMessage(
      isUser: true,
      text: userText,
      at: now,
      attachments: attachments
          .map((a) => LeafAttachmentPreview(name: a.name, mime: a.mime))
          .toList(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
      stagedAttachments: const [],
    );

    final envelope = await _assistant.handleMessage(
      message: trimmed.isEmpty ? '[attachment]' : trimmed,
      context: _ctx,
      categories: _categories,
      bills: _bills,
      goals: _goals,
      history: _buildHistory(),
      attachments: attachments,
    );
    _applyEnvelope(envelope);
  }

  /// Applies a tapped clarification option by merging its patch into the
  /// pending action and either previewing it (if now complete) or asking the
  /// next question locally without a round-trip.
  Future<void> selectClarificationOption({
    required LeafChatMessage source,
    required LeafClarificationOption option,
  }) async {
    final action = source.action;
    if (action == null || source.clarificationField == null) return;

    final mergedData = {...action.data, ...option.patch};
    final resolvedField = source.clarificationField!;
    final remaining = action.missingFields
        .where((field) => !_fieldResolvedBy(field, resolvedField, option.patch))
        .toList(growable: false);

    final updatedAction = LeafPendingAction(
      intent: action.intent,
      confidence: remaining.isEmpty ? 0.95 : action.confidence,
      requiresConfirmation: action.requiresConfirmation,
      isReadOnly: action.isReadOnly,
      missingFields: remaining,
      reason: action.reason,
      data: mergedData,
    );

    // Record the user's selection so the conversation reads naturally.
    final selectionEcho = LeafChatMessage(
      isUser: true,
      text: option.label,
      at: DateTime.now(),
    );

    // Neutralize the original options on the previous clarification so they
    // collapse after selection.
    final priorMessages = state.messages
        .map((message) => identical(message, source)
            ? message.withClarificationCleared()
            : message)
        .toList();

    state = state.copyWith(
      messages: [...priorMessages, selectionEcho],
      pendingAction: remaining.isEmpty ? updatedAction : null,
    );

    if (remaining.isEmpty) {
      final summary = _localPreviewSummary(updatedAction);
      _appendAssistant(
        text: summary,
        kind: LeafMessageKind.actionPreview,
        action: updatedAction,
      );
      state = state.copyWith(pendingAction: updatedAction);
      return;
    }

    // Still more to resolve — fall back to the assistant so it can decide
    // which field to ask about next.
    state = state.copyWith(isLoading: true, error: null);
    final envelope = await _assistant.handleMessage(
      message: 'The user selected ${option.label}.',
      context: _ctx,
      categories: _categories,
      bills: _bills,
      goals: _goals,
      history: _buildHistory(),
    );
    _applyEnvelope(envelope);
  }

  Future<void> confirmPendingAction() async {
    final action = state.pendingAction;
    if (action == null || _confirmPendingInFlight) return;
    _confirmPendingInFlight = true;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _executor.execute(
        action: action,
        categories: _categories,
        goals: _goals,
        bills: _bills,
      );
      final assistantText = await _assistant.buildExecutionResponse(
        action: action,
        success: true,
        result: result,
        context: _ctx,
      );
      _appendAssistant(
        text: assistantText,
        kind: LeafMessageKind.executionResult,
        success: true,
      );
      state = state.copyWith(
        pendingAction: null,
        isLoading: false,
        error: null,
      );
    } on LeafActionException catch (error) {
      await _appendExecutionFailure(action, error.message);
    } catch (error) {
      await _appendExecutionFailure(action, error.toString());
    } finally {
      _confirmPendingInFlight = false;
    }
  }

  void cancelPendingAction() {
    if (state.pendingAction == null) return;
    _appendAssistant(
      text: "Okay, I won't make that change.",
      kind: LeafMessageKind.text,
    );
    state = state.copyWith(pendingAction: null, error: null);
  }

  Future<void> _appendExecutionFailure(
    LeafPendingAction action,
    String errorMessage,
  ) async {
    final assistantText = await _assistant.buildExecutionResponse(
      action: action,
      success: false,
      result: null,
      context: _ctx,
      errorMessage: errorMessage,
    );
    _appendAssistant(
      text: assistantText,
      kind: LeafMessageKind.error,
      success: false,
    );
    state = state.copyWith(
      isLoading: false,
      error: errorMessage,
    );
  }

  void _applyEnvelope(LeafAssistantEnvelope envelope) {
    final kind = switch (envelope.type) {
      LeafEnvelopeType.assistantMessage => LeafMessageKind.text,
      LeafEnvelopeType.clarificationRequest => LeafMessageKind.clarification,
      LeafEnvelopeType.actionPreview => LeafMessageKind.actionPreview,
      LeafEnvelopeType.executionResult => LeafMessageKind.executionResult,
      LeafEnvelopeType.error => LeafMessageKind.error,
    };
    if (envelope.assistantMessage.trim().isNotEmpty) {
      _appendAssistant(
        text: envelope.assistantMessage,
        kind: kind,
        action: envelope.action,
        success: envelope.success,
        clarificationField: envelope.clarificationField,
        clarificationOptions: envelope.clarificationOptions,
      );
    }
    state = state.copyWith(
      pendingAction: envelope.type == LeafEnvelopeType.actionPreview
          ? envelope.action
          : null,
      isLoading: false,
      error: envelope.type == LeafEnvelopeType.error
          ? envelope.assistantMessage
          : null,
      suggestedPrompts: envelope.suggestedPrompts.isEmpty
          ? state.suggestedPrompts
          : envelope.suggestedPrompts,
    );
  }

  void _appendAssistant({
    required String text,
    required LeafMessageKind kind,
    LeafPendingAction? action,
    bool? success,
    String? clarificationField,
    List<LeafClarificationOption> clarificationOptions = const [],
  }) {
    final now = DateTime.now();
    state = state.copyWith(
      messages: [
        ...state.messages,
        LeafChatMessage(
          isUser: false,
          text: text,
          at: now,
          kind: kind,
          action: action,
          success: success,
          clarificationField: clarificationField,
          clarificationOptions: clarificationOptions,
        ),
      ],
    );
  }

  /// Last ~8 turns so Gemini gets continuity without blowing the token budget.
  List<LeafHistoryTurn> _buildHistory() {
    final trimmed = <LeafHistoryTurn>[];
    final source = state.messages;
    // Keep the last 8 turns before the current pending one was added.
    final recent = source.length <= 8
        ? source
        : source.sublist(source.length - 8);
    for (final message in recent) {
      final text = message.text.trim();
      if (text.isEmpty) continue;
      trimmed.add(LeafHistoryTurn(
        role: message.isUser ? 'user' : 'assistant',
        text: text,
      ));
    }
    return trimmed;
  }

  String _localPreviewSummary(LeafPendingAction action) {
    return switch (action.intent) {
      LeafIntent.addExpense => _expensePreviewCopy(action),
      LeafIntent.markBillPaid => _billPreviewCopy(action),
      LeafIntent.createGoal => _goalPreviewCopy(action),
      LeafIntent.addIncome => _incomePreviewCopy(action),
      _ => 'Ready when you are — confirm to apply.',
    };
  }
}

bool _fieldResolvedBy(
  String field,
  String clarificationField,
  Map<String, dynamic> patch,
) {
  // Common field aliases: when the clarification is for `category_id` and the
  // patch supplies both `category_id` and `category_name`, either "missing"
  // entry should be cleared once the user picks an option.
  if (field == clarificationField) return true;
  return switch (clarificationField) {
    'category_id' =>
      field == 'category_name' && patch.containsKey('category_name'),
    'bill_id' => field == 'bill_name' && patch.containsKey('bill_name'),
    'goal_id' => field == 'name' && patch.containsKey('name'),
    _ => false,
  };
}

String _attachmentSummaryText(List<LeafAttachment> attachments) {
  if (attachments.length == 1) return 'Sent an attachment.';
  return 'Sent ${attachments.length} attachments.';
}

String _expensePreviewCopy(LeafPendingAction action) {
  final amount = action.data['amount'];
  final category = action.data['category_name'] as String?;
  final formatted = _asCurrency(amount);
  if (formatted == null) {
    return category == null
        ? 'I can log that expense. Confirm to apply.'
        : 'I can log that to $category. Confirm to apply.';
  }
  if (category == null || category.isEmpty) {
    return 'I can log $formatted as an expense. Confirm to apply.';
  }
  return 'I can log $formatted to $category. Confirm to apply.';
}

String _billPreviewCopy(LeafPendingAction action) {
  final name = action.data['bill_name'] as String?;
  final amount = action.data['amount'];
  final formatted = _asCurrency(amount);
  if (name == null) return 'I can mark that bill paid. Confirm to apply.';
  if (formatted == null) return 'I can mark "$name" paid. Confirm to apply.';
  return 'I can mark "$name" paid for $formatted. Confirm to apply.';
}

String _goalPreviewCopy(LeafPendingAction action) {
  final name = action.data['name'] as String?;
  if (name == null || name.isEmpty) {
    return 'I can create the goal. Confirm to apply.';
  }
  return 'I can create the goal "$name". Confirm to apply.';
}

String _incomePreviewCopy(LeafPendingAction action) {
  final formatted = _asCurrency(action.data['amount']);
  if (formatted == null) return 'I can log the income. Confirm to apply.';
  return 'I can log $formatted of income. Confirm to apply.';
}

String? _asCurrency(Object? raw) {
  final amount = switch (raw) {
    final num value => value.toDouble(),
    final String value => double.tryParse(value),
    _ => null,
  };
  if (amount == null) return null;
  return '\$${amount.toStringAsFixed(2)}';
}

final leafAssistantHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final leafAssistantServiceProvider = Provider<LeafAssistantService>((ref) {
  const baseUrl = String.fromEnvironment('LEAF_API_BASE_URL');
  if (baseUrl.isEmpty) {
    return const MockLeafAssistantService();
  }
  return LeafHttpAssistantService(
    client: ref.watch(leafAssistantHttpClientProvider),
    baseUrl: baseUrl,
  );
});

final leafActionExecutorProvider = Provider<LeafActionExecutor>((ref) {
  return LeafActionExecutor(
    ledgerService: ref.watch(ledgerServiceProvider),
    goalsService: ref.watch(goalsServiceProvider),
    billsService: ref.watch(billsServiceProvider),
  );
});

final leafConversationProvider =
    StateNotifierProvider<LeafConversationController, LeafConversationState>(
        (ref) {
  return LeafConversationController(ref);
});

/// Opening line for the hero card; recomputes with context.
final leafHeroBriefingProvider = Provider<String>((ref) {
  return buildHeroBriefing(ref.watch(leafContextProvider));
});
