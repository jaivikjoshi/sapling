import '../../domain/models/enums.dart';
import 'leaf_context.dart';

enum LeafIntent {
  addExpense,
  addIncome,
  markBillPaid,
  createGoal,
  setPrimaryGoal,
  addRecurringIncome,
  setAllowanceMode,
  setCycleReset,
  setSpendingBaseline,
  reconcileBalance,
  createRecoveryPlan,
  getAllowanceStatus,
  getSpendingSummary,
  getGoalProgress,
  getBillsDue,
  getRecoveryStatus,
  getTransactions,
  clarify,
  unsupported,
  smallTalk,
  unknown,
}

LeafIntent leafIntentFromWire(String? value) {
  return switch (value) {
    'add_expense' => LeafIntent.addExpense,
    'add_income' => LeafIntent.addIncome,
    'mark_bill_paid' => LeafIntent.markBillPaid,
    'create_goal' => LeafIntent.createGoal,
    'set_primary_goal' => LeafIntent.setPrimaryGoal,
    'add_recurring_income' => LeafIntent.addRecurringIncome,
    'set_allowance_mode' => LeafIntent.setAllowanceMode,
    'set_cycle_reset' => LeafIntent.setCycleReset,
    'set_spending_baseline' => LeafIntent.setSpendingBaseline,
    'reconcile_balance' => LeafIntent.reconcileBalance,
    'create_recovery_plan' => LeafIntent.createRecoveryPlan,
    'get_allowance_status' => LeafIntent.getAllowanceStatus,
    'get_spending_summary' => LeafIntent.getSpendingSummary,
    'get_goal_progress' => LeafIntent.getGoalProgress,
    'get_bills_due' => LeafIntent.getBillsDue,
    'get_recovery_status' => LeafIntent.getRecoveryStatus,
    'get_transactions' => LeafIntent.getTransactions,
    'clarify' => LeafIntent.clarify,
    'unsupported' => LeafIntent.unsupported,
    'small_talk' => LeafIntent.smallTalk,
    _ => LeafIntent.unknown,
  };
}

extension LeafIntentX on LeafIntent {
  String get wireValue => switch (this) {
        LeafIntent.addExpense => 'add_expense',
        LeafIntent.addIncome => 'add_income',
        LeafIntent.markBillPaid => 'mark_bill_paid',
        LeafIntent.createGoal => 'create_goal',
        LeafIntent.setPrimaryGoal => 'set_primary_goal',
        LeafIntent.addRecurringIncome => 'add_recurring_income',
        LeafIntent.setAllowanceMode => 'set_allowance_mode',
        LeafIntent.setCycleReset => 'set_cycle_reset',
        LeafIntent.setSpendingBaseline => 'set_spending_baseline',
        LeafIntent.reconcileBalance => 'reconcile_balance',
        LeafIntent.createRecoveryPlan => 'create_recovery_plan',
        LeafIntent.getAllowanceStatus => 'get_allowance_status',
        LeafIntent.getSpendingSummary => 'get_spending_summary',
        LeafIntent.getGoalProgress => 'get_goal_progress',
        LeafIntent.getBillsDue => 'get_bills_due',
        LeafIntent.getRecoveryStatus => 'get_recovery_status',
        LeafIntent.getTransactions => 'get_transactions',
        LeafIntent.clarify => 'clarify',
        LeafIntent.unsupported => 'unsupported',
        LeafIntent.smallTalk => 'small_talk',
        LeafIntent.unknown => 'unknown',
      };

  String get label => switch (this) {
        LeafIntent.addExpense => 'Add expense',
        LeafIntent.addIncome => 'Add income',
        LeafIntent.markBillPaid => 'Mark bill paid',
        LeafIntent.createGoal => 'Create goal',
        LeafIntent.setPrimaryGoal => 'Set primary goal',
        LeafIntent.addRecurringIncome => 'Add recurring income',
        LeafIntent.setAllowanceMode => 'Set allowance mode',
        LeafIntent.setCycleReset => 'Set cycle reset',
        LeafIntent.setSpendingBaseline => 'Set spending baseline',
        LeafIntent.reconcileBalance => 'Reconcile balance',
        LeafIntent.createRecoveryPlan => 'Create recovery plan',
        LeafIntent.getAllowanceStatus => 'Allowance status',
        LeafIntent.getSpendingSummary => 'Spending summary',
        LeafIntent.getGoalProgress => 'Goal progress',
        LeafIntent.getBillsDue => 'Bills due',
        LeafIntent.getRecoveryStatus => 'Recovery status',
        LeafIntent.getTransactions => 'Transactions',
        LeafIntent.clarify => 'Clarify',
        LeafIntent.unsupported => 'Unsupported request',
        LeafIntent.smallTalk => 'Small talk',
        LeafIntent.unknown => 'Unknown action',
      };
}

enum LeafEnvelopeType {
  assistantMessage,
  clarificationRequest,
  actionPreview,
  executionResult,
  error,
}

LeafEnvelopeType leafEnvelopeTypeFromWire(String? value) {
  return switch (value) {
    'assistant_message' => LeafEnvelopeType.assistantMessage,
    'clarification_request' => LeafEnvelopeType.clarificationRequest,
    'action_preview' => LeafEnvelopeType.actionPreview,
    'execution_result' => LeafEnvelopeType.executionResult,
    'error' => LeafEnvelopeType.error,
    _ => LeafEnvelopeType.assistantMessage,
  };
}

extension LeafEnvelopeTypeX on LeafEnvelopeType {
  String get wireValue => switch (this) {
        LeafEnvelopeType.assistantMessage => 'assistant_message',
        LeafEnvelopeType.clarificationRequest => 'clarification_request',
        LeafEnvelopeType.actionPreview => 'action_preview',
        LeafEnvelopeType.executionResult => 'execution_result',
        LeafEnvelopeType.error => 'error',
      };
}

class LeafPendingAction {
  const LeafPendingAction({
    required this.intent,
    required this.confidence,
    required this.requiresConfirmation,
    required this.isReadOnly,
    required this.missingFields,
    required this.reason,
    required this.data,
  });

  final LeafIntent intent;
  final double confidence;
  final bool requiresConfirmation;
  final bool isReadOnly;
  final List<String> missingFields;
  final String reason;
  final Map<String, dynamic> data;

  bool get isComplete => missingFields.isEmpty;

  factory LeafPendingAction.fromJson(Map<String, dynamic> json) {
    return LeafPendingAction(
      intent: leafIntentFromWire(json['intent'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      requiresConfirmation:
          (json['requires_confirmation'] as bool?) ?? true,
      isReadOnly: (json['is_read_only'] as bool?) ?? false,
      missingFields: ((json['missing_fields'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      reason: (json['reason'] as String?) ?? '',
      data: Map<String, dynamic>.from(
        (json['data'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intent': intent.wireValue,
      'confidence': confidence,
      'requires_confirmation': requiresConfirmation,
      'is_read_only': isReadOnly,
      'missing_fields': missingFields,
      'reason': reason,
      'data': data,
    };
  }
}

/// A single tappable answer presented alongside a clarification request.
///
/// When the user taps an option, the client merges [patch] into the
/// pending action's `data` map and clears the matching field from
/// `missing_fields`, avoiding a backend round-trip for the common case.
class LeafClarificationOption {
  const LeafClarificationOption({
    required this.id,
    required this.label,
    this.subtitle,
    this.patch = const {},
  });

  final String id;
  final String label;
  final String? subtitle;
  final Map<String, dynamic> patch;

  factory LeafClarificationOption.fromJson(Map<String, dynamic> json) {
    return LeafClarificationOption(
      id: (json['id'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      subtitle: json['subtitle'] as String?,
      patch: Map<String, dynamic>.from(
        (json['patch'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (subtitle != null) 'subtitle': subtitle,
        'patch': patch,
      };
}

class LeafAssistantEnvelope {
  const LeafAssistantEnvelope({
    required this.type,
    required this.assistantMessage,
    this.intent,
    this.action,
    this.success,
    this.result,
    this.errorCode,
    this.suggestedPrompts = const [],
    this.clarificationField,
    this.clarificationOptions = const [],
  });

  final LeafEnvelopeType type;
  final String assistantMessage;
  final LeafIntent? intent;
  final LeafPendingAction? action;
  final bool? success;
  final Map<String, dynamic>? result;
  final String? errorCode;
  final List<String> suggestedPrompts;
  final String? clarificationField;
  final List<LeafClarificationOption> clarificationOptions;

  factory LeafAssistantEnvelope.assistant(
    String message, {
    List<String> suggestedPrompts = const [],
  }) {
    return LeafAssistantEnvelope(
      type: LeafEnvelopeType.assistantMessage,
      assistantMessage: message,
      suggestedPrompts: suggestedPrompts,
    );
  }

  factory LeafAssistantEnvelope.clarification(
    String message, {
    LeafPendingAction? action,
    List<String> suggestedPrompts = const [],
    String? clarificationField,
    List<LeafClarificationOption> clarificationOptions = const [],
  }) {
    return LeafAssistantEnvelope(
      type: LeafEnvelopeType.clarificationRequest,
      assistantMessage: message,
      action: action,
      intent: action?.intent,
      suggestedPrompts: suggestedPrompts,
      clarificationField: clarificationField,
      clarificationOptions: clarificationOptions,
    );
  }

  factory LeafAssistantEnvelope.preview({
    required String message,
    required LeafPendingAction action,
    List<String> suggestedPrompts = const [],
  }) {
    return LeafAssistantEnvelope(
      type: LeafEnvelopeType.actionPreview,
      assistantMessage: message,
      intent: action.intent,
      action: action,
      suggestedPrompts: suggestedPrompts,
    );
  }

  factory LeafAssistantEnvelope.execution({
    required String message,
    required LeafIntent intent,
    required bool success,
    Map<String, dynamic>? result,
    List<String> suggestedPrompts = const [],
  }) {
    return LeafAssistantEnvelope(
      type: LeafEnvelopeType.executionResult,
      assistantMessage: message,
      intent: intent,
      success: success,
      result: result,
      suggestedPrompts: suggestedPrompts,
    );
  }

  factory LeafAssistantEnvelope.error(
    String message, {
    String? errorCode,
    List<String> suggestedPrompts = const [],
  }) {
    return LeafAssistantEnvelope(
      type: LeafEnvelopeType.error,
      assistantMessage: message,
      errorCode: errorCode,
      suggestedPrompts: suggestedPrompts,
    );
  }

  factory LeafAssistantEnvelope.fromJson(Map<String, dynamic> json) {
    final type = leafEnvelopeTypeFromWire(json['type'] as String?);
    final actionJson = json['action'];
    final action = actionJson is Map<String, dynamic>
        ? LeafPendingAction.fromJson(actionJson)
        : null;
    final options = ((json['clarification_options'] as List?) ?? const [])
        .whereType<Map>()
        .map((raw) => LeafClarificationOption.fromJson(
              Map<String, dynamic>.from(raw),
            ))
        .where((option) => option.id.isNotEmpty && option.label.isNotEmpty)
        .toList();
    return LeafAssistantEnvelope(
      type: type,
      assistantMessage: (json['assistant_message'] as String?) ?? '',
      intent: leafIntentFromWire(
        (json['intent'] ?? actionJson?['intent']) as String?,
      ),
      action: action,
      success: json['success'] as bool?,
      result: json['result'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['result'] as Map<String, dynamic>)
          : null,
      errorCode: json['error_code'] as String?,
      suggestedPrompts: ((json['suggested_prompts'] as List?) ?? const [])
          .whereType<String>()
          .toList(),
      clarificationField: json['clarification_field'] as String?,
      clarificationOptions: options,
    );
  }

  LeafAssistantEnvelope copyWith({
    LeafEnvelopeType? type,
    String? assistantMessage,
    LeafIntent? intent,
    LeafPendingAction? action,
    bool? success,
    Map<String, dynamic>? result,
    String? errorCode,
    List<String>? suggestedPrompts,
    String? clarificationField,
    List<LeafClarificationOption>? clarificationOptions,
  }) {
    return LeafAssistantEnvelope(
      type: type ?? this.type,
      assistantMessage: assistantMessage ?? this.assistantMessage,
      intent: intent ?? this.intent,
      action: action ?? this.action,
      success: success ?? this.success,
      result: result ?? this.result,
      errorCode: errorCode ?? this.errorCode,
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
      clarificationField: clarificationField ?? this.clarificationField,
      clarificationOptions: clarificationOptions ?? this.clarificationOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.wireValue,
      'assistant_message': assistantMessage,
      if (intent != null) 'intent': intent!.wireValue,
      if (action != null) 'action': action!.toJson(),
      if (success != null) 'success': success,
      if (result != null) 'result': result,
      if (errorCode != null) 'error_code': errorCode,
      if (suggestedPrompts.isNotEmpty) 'suggested_prompts': suggestedPrompts,
      if (clarificationField != null) 'clarification_field': clarificationField,
      if (clarificationOptions.isNotEmpty)
        'clarification_options':
            clarificationOptions.map((option) => option.toJson()).toList(),
    };
  }
}

/// Minimal attachment payload the app sends to the Leaf backend.
///
/// [dataBase64] is the raw file bytes base64-encoded so the worker can pass
/// them through to Gemini as inline_data without needing an object store.
class LeafAttachment {
  const LeafAttachment({
    required this.name,
    required this.mime,
    required this.dataBase64,
    this.sizeBytes,
  });

  final String name;
  final String mime;
  final String dataBase64;
  final int? sizeBytes;

  bool get isPdf => mime == 'application/pdf';
  bool get isImage => mime.startsWith('image/');

  Map<String, dynamic> toJson() => {
        'name': name,
        'mime': mime,
        'data': dataBase64,
      };
}

class LeafHistoryTurn {
  const LeafHistoryTurn({required this.role, required this.text});

  final String role; // 'user' | 'assistant'
  final String text;

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

class LeafEntityRef {
  const LeafEntityRef({
    required this.id,
    required this.name,
    this.amount,
    this.dueDate,
  });

  final String id;
  final String name;
  final double? amount;
  final String? dueDate;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (amount != null) 'amount': amount,
        if (dueDate != null) 'due_date': dueDate,
      };
}

class LeafBackendContext {
  const LeafBackendContext({
    required this.greetingName,
    required this.allowanceMode,
    this.balance,
    this.dailyAllowance,
    this.remainingToday,
    this.todaySpend,
    this.primaryGoalName,
    this.nextBillName,
    this.categories = const [],
    this.upcomingBills = const [],
    this.goals = const [],
  });

  final String greetingName;
  final AllowanceMode allowanceMode;
  final double? balance;
  final double? dailyAllowance;
  final double? remainingToday;
  final double? todaySpend;
  final String? primaryGoalName;
  final String? nextBillName;
  final List<LeafEntityRef> categories;
  final List<LeafEntityRef> upcomingBills;
  final List<LeafEntityRef> goals;

  factory LeafBackendContext.fromLeafContext(
    LeafContext context, {
    List<LeafEntityRef> categories = const [],
    List<LeafEntityRef> upcomingBills = const [],
    List<LeafEntityRef> goals = const [],
  }) {
    return LeafBackendContext(
      greetingName: context.greetingName,
      allowanceMode: context.allowanceMode,
      balance: context.balance,
      dailyAllowance: context.dailyAllowance,
      remainingToday: context.remainingToday,
      todaySpend: context.todaySpend,
      primaryGoalName: context.primaryGoal?.name,
      nextBillName: context.nextBill?.name,
      categories: categories,
      upcomingBills: upcomingBills,
      goals: goals,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'greeting_name': greetingName,
      'allowance_mode': allowanceMode.name,
      'balance': balance,
      'daily_allowance': dailyAllowance,
      'remaining_today': remainingToday,
      'today_spend': todaySpend,
      'primary_goal_name': primaryGoalName,
      'next_bill_name': nextBillName,
      if (categories.isNotEmpty)
        'categories': categories.map((e) => e.toJson()).toList(),
      if (upcomingBills.isNotEmpty)
        'upcoming_bills': upcomingBills.map((e) => e.toJson()).toList(),
      if (goals.isNotEmpty) 'goals': goals.map((e) => e.toJson()).toList(),
    };
  }
}
