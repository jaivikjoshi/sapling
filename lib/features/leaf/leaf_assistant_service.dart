import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/db/leko_database.dart';
import '../../core/utils/currency_formatter.dart';
import 'leaf_assistant_responses.dart';
import 'leaf_clarification_options.dart';
import 'leaf_context.dart';
import 'leaf_models.dart';

abstract class LeafAssistantService {
  Future<LeafAssistantEnvelope> handleMessage({
    required String message,
    required LeafContext context,
    required List<Category> categories,
    required List<Bill> bills,
    required List<Goal> goals,
    List<LeafHistoryTurn> history = const [],
    List<LeafAttachment> attachments = const [],
  });

  Future<String> buildExecutionResponse({
    required LeafPendingAction action,
    required bool success,
    required Map<String, dynamic>? result,
    required LeafContext context,
    String? errorMessage,
  });
}

class LeafHttpAssistantService implements LeafAssistantService {
  LeafHttpAssistantService({
    required http.Client client,
    required String baseUrl,
  }) : _client = client,
       _baseUrl =
           baseUrl.endsWith('/')
               ? baseUrl.substring(0, baseUrl.length - 1)
               : baseUrl;

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<LeafAssistantEnvelope> handleMessage({
    required String message,
    required LeafContext context,
    required List<Category> categories,
    required List<Bill> bills,
    required List<Goal> goals,
    List<LeafHistoryTurn> history = const [],
    List<LeafAttachment> attachments = const [],
  }) async {
    try {
      final backendContext = LeafBackendContext.fromLeafContext(
        context,
        categories: _categoriesToRefs(categories),
        upcomingBills: _billsToRefs(bills),
        goals: _goalsToRefs(goals),
      );
      final response = await _post(
        '/assistant/message',
        body: {
          'message': message,
          'context': backendContext.toJson(),
          if (history.isNotEmpty)
            'history': history.map((turn) => turn.toJson()).toList(),
          if (attachments.isNotEmpty)
            'attachments':
                attachments.map((attachment) => attachment.toJson()).toList(),
        },
      );
      return LeafAssistantEnvelope.fromJson(response);
    } catch (_) {
      return LeafAssistantEnvelope.error(
        'Leaf couldn’t reach the assistant service right now. Check the backend and try again.',
      );
    }
  }

  @override
  Future<String> buildExecutionResponse({
    required LeafPendingAction action,
    required bool success,
    required Map<String, dynamic>? result,
    required LeafContext context,
    String? errorMessage,
  }) async {
    try {
      final response = await _post(
        '/assistant/respond',
        body: {
          'action': action.toJson(),
          'success': success,
          'result': result,
          'error_message': errorMessage,
          'context': LeafBackendContext.fromLeafContext(context).toJson(),
        },
      );
      return (response['assistant_message'] as String?) ??
          (success
              ? 'Done.'
              : 'That didn’t go through. Check the details and try again.');
    } catch (_) {
      return success
          ? 'Done.'
          : (errorMessage ??
              'That didn’t go through. Check the details and try again.');
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Assistant request failed with ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Assistant response was not a JSON object.');
    }
    return decoded;
  }
}

class MockLeafAssistantService implements LeafAssistantService {
  const MockLeafAssistantService();

  @override
  Future<LeafAssistantEnvelope> handleMessage({
    required String message,
    required LeafContext context,
    required List<Category> categories,
    required List<Bill> bills,
    required List<Goal> goals,
    List<LeafHistoryTurn> history = const [],
    List<LeafAttachment> attachments = const [],
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return LeafAssistantEnvelope.assistant(
        'Ask about your budget, ask for advice, or tell me something to record.',
        suggestedPrompts: _defaultPrompts,
      );
    }

    if (attachments.isNotEmpty) {
      return LeafAssistantEnvelope.assistant(
        'I got your attachment. In dev mode I can\'t parse images or PDFs, but the live assistant will read receipts and statements for you.',
        suggestedPrompts: _defaultPrompts,
      );
    }

    final writeEnvelope = _tryBuildWritePreview(
      message: trimmed,
      categories: categories,
      bills: bills,
    );
    if (writeEnvelope != null) return writeEnvelope;

    return LeafAssistantEnvelope.assistant(
      responseForFreeText(context, trimmed),
      suggestedPrompts: _defaultPrompts,
    );
  }

  @override
  Future<String> buildExecutionResponse({
    required LeafPendingAction action,
    required bool success,
    required Map<String, dynamic>? result,
    required LeafContext context,
    String? errorMessage,
  }) async {
    if (!success) {
      return errorMessage ??
          'I couldn’t finish that change. Check the details and try again.';
    }
    return switch (action.intent) {
      LeafIntent.addExpense => _expenseSuccess(result),
      LeafIntent.addIncome => _incomeSuccess(result),
      LeafIntent.markBillPaid => _billSuccess(result),
      LeafIntent.createGoal => _goalSuccess(result),
      _ => 'Done.',
    };
  }
}

List<LeafEntityRef> _categoriesToRefs(List<Category> categories) {
  // Cap list so the payload stays small; categories the user actually uses
  // matter more than every preset, so we forward the whole list up to 40.
  return categories
      .take(40)
      .map((category) => LeafEntityRef(id: category.id, name: category.name))
      .toList();
}

List<LeafEntityRef> _billsToRefs(List<Bill> bills) {
  final sorted = [...bills]
    ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  return sorted
      .take(12)
      .map(
        (bill) => LeafEntityRef(
          id: bill.id,
          name: bill.name,
          amount: bill.amount,
          dueDate: bill.nextDueDate.toIso8601String().split('T').first,
        ),
      )
      .toList();
}

List<LeafEntityRef> _goalsToRefs(List<Goal> goals) {
  return goals
      .take(12)
      .map(
        (goal) => LeafEntityRef(
          id: goal.id,
          name: goal.name,
          amount: goal.targetAmount,
        ),
      )
      .toList();
}

const List<String> _defaultPrompts = <String>[
  'How much can I spend today?',
  'What bills are coming up?',
  'Give me a budgeting tip',
  r'Add my $25 dinner',
];

LeafAssistantEnvelope? _tryBuildWritePreview({
  required String message,
  required List<Category> categories,
  required List<Bill> bills,
}) {
  final normalized = message.toLowerCase();

  if (_looksLikeExpense(normalized)) {
    final amount = _extractAmount(message);
    final date = _extractDate(message) ?? DateTime.now();
    final matched = _extractExplicitCategory(message, categories);
    final merchant = _extractMerchant(message);
    final missing = <String>[
      if (amount == null) 'amount',
      if (matched == null) 'category_name',
    ];
    final action = LeafPendingAction(
      intent: LeafIntent.addExpense,
      confidence: missing.isEmpty ? 0.92 : 0.68,
      requiresConfirmation: true,
      isReadOnly: false,
      missingFields: missing,
      reason: 'User wants to log an expense.',
      data: {
        'amount': amount,
        'date': _isoDay(date),
        'category_id': matched?.id,
        'category_name': matched?.name,
        'merchant': merchant,
      },
    );

    if (amount == null) {
      return LeafAssistantEnvelope.clarification(
        'I can log that — how much was it?',
        action: action,
        clarificationField: 'amount',
      );
    }
    if (matched == null) {
      return LeafAssistantEnvelope.clarification(
        'What category should I use?',
        action: action,
        clarificationField: 'category_id',
        clarificationOptions: standardExpenseCategoryOptions(categories),
      );
    }
    return LeafAssistantEnvelope.preview(
      message:
          'I can log ${formatCurrency(amount)} to ${matched.name} for ${_friendlyDay(date)}. Want me to add it?',
      action: action,
      suggestedPrompts: _defaultPrompts,
    );
  }

  if (_looksLikeIncome(normalized)) {
    final amount = _extractAmount(message);
    final date = _extractDate(message) ?? DateTime.now();
    final source = _extractIncomeSource(message);
    final action = LeafPendingAction(
      intent: LeafIntent.addIncome,
      confidence: amount == null ? 0.7 : 0.91,
      requiresConfirmation: true,
      isReadOnly: false,
      missingFields: amount == null ? const ['amount'] : const [],
      reason: 'User wants to log income.',
      data: {
        'amount': amount,
        'date': _isoDay(date),
        'source': source,
        'posting_type': 'manual_one_time',
      },
    );
    if (amount == null) {
      return LeafAssistantEnvelope.clarification(
        'I can log the income — how much was it?',
        action: action,
        clarificationField: 'amount',
      );
    }
    return LeafAssistantEnvelope.preview(
      message:
          'I can log ${formatCurrency(amount)} of income for ${_friendlyDay(date)}. Want me to add it?',
      action: action,
      suggestedPrompts: _defaultPrompts,
    );
  }

  if (_looksLikeBillPayment(normalized)) {
    final bill = _extractBill(message, bills);
    final amount = _extractAmount(message);
    final date = _extractDate(message) ?? DateTime.now();
    final action = LeafPendingAction(
      intent: LeafIntent.markBillPaid,
      confidence: bill == null ? 0.69 : 0.9,
      requiresConfirmation: true,
      isReadOnly: false,
      missingFields: bill == null ? const ['bill_id'] : const [],
      reason: 'User wants to mark a bill as paid.',
      data: {
        'bill_id': bill?.id,
        'bill_name': bill?.name,
        'amount': amount ?? bill?.amount,
        'date': _isoDay(date),
      },
    );
    if (bill == null) {
      final shortlist = bills.take(6).toList();
      return LeafAssistantEnvelope.clarification(
        'Which bill do you mean?',
        action: action,
        clarificationField: 'bill_id',
        clarificationOptions:
            shortlist
                .map(
                  (candidate) => LeafClarificationOption(
                    id: candidate.id,
                    label: candidate.name,
                    subtitle: formatCurrency(candidate.amount),
                    patch: {
                      'bill_id': candidate.id,
                      'bill_name': candidate.name,
                      'amount': candidate.amount,
                    },
                  ),
                )
                .toList(),
      );
    }
    return LeafAssistantEnvelope.preview(
      message:
          'I can mark “${bill.name}” paid for ${formatCurrency(amount ?? bill.amount)} on ${_friendlyDay(date)}. Want me to do that?',
      action: action,
      suggestedPrompts: _defaultPrompts,
    );
  }

  if (_looksLikeGoal(normalized)) {
    final amount = _extractAmount(message);
    final targetDate = _extractDate(message);
    final goalName = _extractGoalName(message);
    final action = LeafPendingAction(
      intent: LeafIntent.createGoal,
      confidence:
          goalName != null && amount != null && targetDate != null ? 0.9 : 0.66,
      requiresConfirmation: true,
      isReadOnly: false,
      missingFields: [
        if (goalName == null) 'name',
        if (amount == null) 'target_amount',
        if (targetDate == null) 'target_date',
      ],
      reason: 'User wants to create a goal.',
      data: {
        'name': goalName,
        'target_amount': amount,
        'target_date': targetDate != null ? _isoDay(targetDate) : null,
        'saving_style': 'natural',
        'set_as_primary': true,
      },
    );
    if (action.missingFields.isNotEmpty) {
      return LeafAssistantEnvelope.clarification(
        'I can set up that goal — I still need ${action.missingFields.join(', ')}.',
        action: action,
      );
    }
    return LeafAssistantEnvelope.preview(
      message:
          'I can create the goal “$goalName” for ${formatCurrency(amount!)} by ${_friendlyDay(targetDate!)} and set it as primary. Want me to do that?',
      action: action,
      suggestedPrompts: _defaultPrompts,
    );
  }

  return null;
}

bool _looksLikeExpense(String input) {
  return RegExp(
        r'\b(add|log|track|spent|expense|bought|paid)\b',
      ).hasMatch(input) &&
      RegExp(r'(\$|\b\d)').hasMatch(input) &&
      !RegExp(
        r'\b(goal|save|saving|income|paycheck|salary|bill)\b',
      ).hasMatch(input);
}

bool _looksLikeIncome(String input) {
  return RegExp(
        r'\b(add|log|received|got|income|paycheck|salary|deposit)\b',
      ).hasMatch(input) &&
      RegExp(r'(\$|\b\d)').hasMatch(input);
}

bool _looksLikeBillPayment(String input) {
  return RegExp(r'\b(paid|pay|mark)\b').hasMatch(input) &&
      RegExp(r'\bbill\b').hasMatch(input);
}

bool _looksLikeGoal(String input) {
  return RegExp(
    r'\b(goal|save for|saving for|start goal|create goal)\b',
  ).hasMatch(input);
}

double? _extractAmount(String raw) {
  final match = RegExp(r'\$?\s?(\d+(?:\.\d{1,2})?)').firstMatch(raw);
  if (match == null) return null;
  return double.tryParse(match.group(1)!);
}

DateTime? _extractDate(String raw) {
  final lower = raw.toLowerCase();
  final now = DateTime.now();
  if (lower.contains('today')) {
    return DateTime(now.year, now.month, now.day);
  }
  if (lower.contains('tomorrow')) {
    final day = now.add(const Duration(days: 1));
    return DateTime(day.year, day.month, day.day);
  }
  final monthDay = RegExp(
    r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\s+(\d{1,2})\b',
    caseSensitive: false,
  ).firstMatch(raw);
  if (monthDay != null) {
    final month = _monthNumber(monthDay.group(1)!);
    final day = int.tryParse(monthDay.group(2)!);
    if (month != null && day != null) {
      final candidate = DateTime(now.year, month, day);
      return candidate.isBefore(DateTime(now.year, now.month, now.day))
          ? DateTime(now.year + 1, month, day)
          : candidate;
    }
  }
  return null;
}

int? _monthNumber(String raw) {
  return switch (raw.toLowerCase()) {
    'jan' => 1,
    'feb' => 2,
    'mar' => 3,
    'apr' => 4,
    'may' => 5,
    'jun' => 6,
    'jul' => 7,
    'aug' => 8,
    'sep' || 'sept' => 9,
    'oct' => 10,
    'nov' => 11,
    'dec' => 12,
    _ => null,
  };
}

Category? _extractExplicitCategory(String raw, List<Category> categories) {
  final lower = raw.toLowerCase();
  for (final category in categories) {
    final name = category.name.toLowerCase();
    if (lower.contains(name)) return category;
    final words = name.split(RegExp(r'[/& ]+'));
    if (words.any((word) => word.length > 4 && lower.contains(word))) {
      return category;
    }
  }
  return null;
}

Bill? _extractBill(String raw, List<Bill> bills) {
  final lower = raw.toLowerCase();
  for (final bill in bills) {
    if (lower.contains(bill.name.toLowerCase())) return bill;
    final words = bill.name.toLowerCase().split(RegExp(r'[/& ]+'));
    if (words.any((word) => word.length > 3 && lower.contains(word))) {
      return bill;
    }
  }
  return null;
}

String? _extractMerchant(String raw) {
  final cleaned =
      raw
          .replaceAll(
            RegExp(r'^\s*(add|log|track)\s+', caseSensitive: false),
            '',
          )
          .replaceAll(RegExp(r'\$?\s?\d+(?:\.\d{1,2})?'), '')
          .trim();
  if (cleaned.isEmpty) return null;
  return cleaned.length > 40 ? cleaned.substring(0, 40).trim() : cleaned;
}

String? _extractIncomeSource(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('paycheck') || lower.contains('salary')) return 'Paycheck';
  if (lower.contains('refund')) return 'Refund';
  if (lower.contains('bonus')) return 'Bonus';
  return null;
}

String? _extractGoalName(String raw) {
  final quoteMatch = RegExp(r'"([^"]+)"').firstMatch(raw);
  if (quoteMatch != null) {
    return quoteMatch.group(1)!.trim();
  }
  final forMatch = RegExp(
    r'(?:for|goal)\s+([a-zA-Z][a-zA-Z ]{2,40})',
  ).firstMatch(raw);
  if (forMatch == null) return null;
  final candidate = forMatch.group(1)!.trim();
  final stop = RegExp(
    r'\b(by|on|at|\$)\b',
    caseSensitive: false,
  ).firstMatch(candidate);
  if (stop == null) return candidate.trim();
  return candidate.substring(0, stop.start).trim();
}

String _friendlyDay(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(value.year, value.month, value.day);
  if (day == today) return 'today';
  if (day == today.add(const Duration(days: 1))) return 'tomorrow';
  final months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month]} ${value.day}';
}

String _isoDay(DateTime value) {
  final day = DateTime(value.year, value.month, value.day);
  return day.toIso8601String().split('T').first;
}

String _expenseSuccess(Map<String, dynamic>? result) {
  final amount = result?['amount'] as num?;
  final category = result?['category_name'] as String?;
  if (amount == null) return 'Added the expense.';
  if (category == null || category.isEmpty) {
    return 'Added your ${formatCurrency(amount.toDouble())} expense.';
  }
  return 'Added ${formatCurrency(amount.toDouble())} to $category.';
}

String _incomeSuccess(Map<String, dynamic>? result) {
  final amount = result?['amount'] as num?;
  if (amount == null) return 'Added the income.';
  return 'Added ${formatCurrency(amount.toDouble())} of income.';
}

String _billSuccess(Map<String, dynamic>? result) {
  final name = result?['bill_name'] as String?;
  final amount = result?['amount'] as num?;
  if (name == null || amount == null) return 'Marked the bill paid.';
  return 'Marked “$name” paid for ${formatCurrency(amount.toDouble())}.';
}

String _goalSuccess(Map<String, dynamic>? result) {
  final name = result?['name'] as String?;
  if (name == null || name.isEmpty) return 'Created the goal.';
  return 'Created the goal “$name”.';
}
