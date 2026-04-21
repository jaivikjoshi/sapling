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
  });

  final bool isUser;
  final String text;
  final DateTime at;
  final LeafMessageKind kind;
  final LeafPendingAction? action;
  final bool? success;
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
  });

  final List<LeafChatMessage> messages;
  final LeafPendingAction? pendingAction;
  final bool isLoading;
  final String? error;
  final List<String> suggestedPrompts;

  LeafConversationState copyWith({
    List<LeafChatMessage>? messages,
    Object? pendingAction = _leafNoChange,
    bool? isLoading,
    Object? error = _leafNoChange,
    List<String>? suggestedPrompts,
  }) {
    return LeafConversationState(
      messages: messages ?? this.messages,
      pendingAction: pendingAction == _leafNoChange
          ? this.pendingAction
          : pendingAction as LeafPendingAction?,
      isLoading: isLoading ?? this.isLoading,
      error: error == _leafNoChange ? this.error : error as String?,
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
    );
  }
}

const List<String> _defaultLeafPrompts = <String>[
  'How much can I spend today?',
  'What bills are coming up?',
  'How is my goal doing?',
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
                    'I’m Leaf. Ask about your budget, or tell me something to record and I’ll preview it before anything changes.',
                at: DateTime.now(),
              ),
            ],
          ),
        );

  final Ref ref;

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
    state = LeafConversationState(
      messages: [
        LeafChatMessage(
          isUser: false,
          text:
              'Fresh thread. Ask about spending, bills, goals, or tell me what you want to log.',
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

  Future<void> submitFreeText(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    state = state.copyWith(
      messages: [
        ...state.messages,
        LeafChatMessage(isUser: true, text: trimmed, at: now),
      ],
      isLoading: true,
      error: null,
    );

    final envelope = await _assistant.handleMessage(
      message: trimmed,
      context: _ctx,
      categories: _categories,
      bills: _bills,
      goals: _goals,
    );
    _applyEnvelope(envelope);
  }

  Future<void> confirmPendingAction() async {
    final action = state.pendingAction;
    if (action == null) return;
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
    }
  }

  void cancelPendingAction() {
    if (state.pendingAction == null) return;
    _appendAssistant(
      text: 'Okay, I won’t make that change.',
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
        ),
      ],
    );
  }
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
