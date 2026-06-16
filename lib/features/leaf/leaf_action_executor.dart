import '../../data/db/leko_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/bills_service.dart';
import '../../domain/services/goals_service.dart';
import '../../domain/services/ledger_service.dart';
import 'leaf_models.dart';

class LeafActionException implements Exception {
  const LeafActionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LeafActionExecutor {
  const LeafActionExecutor({
    required LedgerService ledgerService,
    required GoalsService goalsService,
    required BillsService billsService,
  }) : _ledgerService = ledgerService,
       _goalsService = goalsService,
       _billsService = billsService;

  final LedgerService _ledgerService;
  final GoalsService _goalsService;
  final BillsService _billsService;

  Future<Map<String, dynamic>> execute({
    required LeafPendingAction action,
    required List<Category> categories,
    required List<Goal> goals,
    required List<Bill> bills,
  }) async {
    return switch (action.intent) {
      LeafIntent.addExpense => _addExpense(
        action: action,
        categories: categories,
      ),
      LeafIntent.addIncome => _addIncome(action),
      LeafIntent.markBillPaid => _markBillPaid(action: action, bills: bills),
      LeafIntent.createGoal => _createGoal(action: action, goals: goals),
      _ =>
        throw LeafActionException(
          'Leaf can’t execute ${action.intent.label.toLowerCase()} yet.',
        ),
    };
  }

  Future<Map<String, dynamic>> _addExpense({
    required LeafPendingAction action,
    required List<Category> categories,
  }) async {
    final amount = _requirePositiveDouble(action.data['amount'], 'amount');
    final date = _parseDate(action.data['date']) ?? DateTime.now();
    final category = _resolveCategory(
      categories: categories,
      categoryId: action.data['category_id'] as String?,
      categoryName: action.data['category_name'] as String?,
      merchant: action.data['merchant'] as String?,
      note: action.data['note'] as String?,
    );
    if (category == null) {
      throw const LeafActionException(
        'I need a category before I can log that expense.',
      );
    }
    final label =
        _spendLabelFromWire(action.data['label'] as String?) ??
        _spendLabelFromWire(category.defaultLabel) ??
        SpendLabel.orange;
    final note = _joinNoteParts(
      action.data['merchant'] as String?,
      action.data['note'] as String?,
    );

    final transactionId = await _ledgerService.addExpense(
      amount: amount,
      date: date,
      categoryId: category.id,
      label: label,
      note: note,
      linkedBillId: action.data['linked_bill_id'] as String?,
      linkedSplitEntryId: linkedSplitEntryIdFromLeafActionData(action.data),
    );

    return {
      'transaction_id': transactionId,
      'amount': amount,
      'category_name': category.name,
      'date': date.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _addIncome(LeafPendingAction action) async {
    final amount = _requirePositiveDouble(action.data['amount'], 'amount');
    final date = _parseDate(action.data['date']) ?? DateTime.now();
    final postingType =
        _incomePostingTypeFromWire(action.data['posting_type'] as String?) ??
        IncomePostingType.manualOneTime;

    final transactionId = await _ledgerService.addIncome(
      amount: amount,
      date: date,
      postingType: postingType,
      source: action.data['source'] as String?,
      note: action.data['note'] as String?,
      linkedRecurringIncomeId:
          action.data['linked_recurring_income_id'] as String?,
    );

    return {
      'transaction_id': transactionId,
      'amount': amount,
      'source': action.data['source'],
      'date': date.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _markBillPaid({
    required LeafPendingAction action,
    required List<Bill> bills,
  }) async {
    final bill = _resolveBill(
      bills: bills,
      billId: action.data['bill_id'] as String?,
      billName: action.data['bill_name'] as String?,
    );
    if (bill == null) {
      throw const LeafActionException(
        'I couldn’t match that bill to anything in your list.',
      );
    }
    final amount = _positiveDoubleOrNull(action.data['amount']) ?? bill.amount;
    final paidDate = _parseDate(action.data['date']) ?? DateTime.now();
    final result = await _billsService.markPaid(
      billId: bill.id,
      amountOverride: amount,
      paidDate: paidDate,
    );
    return {
      'transaction_id': result.transactionId,
      'bill_id': bill.id,
      'bill_name': bill.name,
      'amount': result.paidAmount,
      'next_due_date': result.updatedBill.nextDueDate.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _createGoal({
    required LeafPendingAction action,
    required List<Goal> goals,
  }) async {
    final name = (action.data['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      throw const LeafActionException('I need a goal name first.');
    }
    final targetAmount = _requirePositiveDouble(
      action.data['target_amount'],
      'target_amount',
    );
    final targetDate = _parseDate(action.data['target_date']);
    if (targetDate == null) {
      throw const LeafActionException(
        'I need a valid target date for the goal.',
      );
    }
    final savingStyle =
        _savingStyleFromWire(action.data['saving_style'] as String?) ??
        SavingStyle.natural;

    final goalId = await _goalsService.create(
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
      savingStyle: savingStyle,
      priorityOrder: goals.length,
    );

    final setAsPrimary = action.data['set_as_primary'] == true;
    if (setAsPrimary) {
      await _goalsService.setPrimaryGoal(goalId);
    }

    return {
      'goal_id': goalId,
      'name': name,
      'target_amount': targetAmount,
      'target_date': targetDate.toIso8601String(),
      'set_as_primary': setAsPrimary,
    };
  }

  Category? _resolveCategory({
    required List<Category> categories,
    String? categoryId,
    String? categoryName,
    String? merchant,
    String? note,
  }) {
    if (categoryId != null && categoryId.isNotEmpty) {
      for (final category in categories) {
        if (category.id == categoryId) return category;
      }
    }

    final target = categoryName?.trim().toLowerCase();
    if (target != null && target.isNotEmpty) {
      for (final category in categories) {
        if (category.name.trim().toLowerCase() == target) return category;
      }
      for (final category in categories) {
        if (category.name.trim().toLowerCase().contains(target)) {
          return category;
        }
      }
    }

    final raw = '${merchant ?? ''} ${note ?? ''}'.toLowerCase();
    if (raw.contains('dinner') ||
        raw.contains('lunch') ||
        raw.contains('coffee') ||
        raw.contains('restaurant')) {
      return _findCategoryByContains(categories, 'dining');
    }
    if (raw.contains('uber') ||
        raw.contains('train') ||
        raw.contains('bus') ||
        raw.contains('gas')) {
      return _findCategoryByContains(categories, 'transport');
    }
    if (raw.contains('grocery') ||
        raw.contains('whole foods') ||
        raw.contains('market')) {
      return _findCategoryByContains(categories, 'groc');
    }
    if (raw.contains('spotify') ||
        raw.contains('netflix') ||
        raw.contains('subscription')) {
      return _findCategoryByContains(categories, 'subscription');
    }
    return null;
  }

  Category? _findCategoryByContains(List<Category> categories, String query) {
    final lowered = query.toLowerCase();
    for (final category in categories) {
      if (category.name.toLowerCase().contains(lowered)) return category;
    }
    return null;
  }

  Bill? _resolveBill({
    required List<Bill> bills,
    String? billId,
    String? billName,
  }) {
    if (billId != null && billId.isNotEmpty) {
      for (final bill in bills) {
        if (bill.id == billId) return bill;
      }
    }
    final target = billName?.trim().toLowerCase();
    if (target == null || target.isEmpty) return null;
    for (final bill in bills) {
      if (bill.name.toLowerCase() == target) return bill;
    }
    for (final bill in bills) {
      if (bill.name.toLowerCase().contains(target)) return bill;
    }
    return null;
  }
}

/// Reads a split **entry** id from Leaf assistant `action.data`.
///
/// Transactions store `linked_split_entry_id`, which must reference
/// `split_entries.id`, not a person id. Canonical payloads use snake_case keys
/// from the assistant API; legacy `split_person_id` is ignored because it
/// often carries the wrong entity type and corrupts balances.
String? linkedSplitEntryIdFromLeafActionData(Map<String, dynamic> data) {
  const keys = <String>[
    'linked_split_entry_id',
    'linkedSplitEntryId',
    'split_entry_id',
    'splitEntryId',
  ];
  for (final key in keys) {
    final raw = data[key];
    if (raw is String) {
      final v = raw.trim();
      if (v.isNotEmpty) return v;
    }
  }
  return null;
}

double _requirePositiveDouble(Object? raw, String fieldName) {
  final value = _positiveDoubleOrNull(raw);
  if (value == null) {
    throw LeafActionException(
      'I need a valid $fieldName before I can do that.',
    );
  }
  return value;
}

double? _positiveDoubleOrNull(Object? raw) {
  final value = switch (raw) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text.trim()),
    _ => null,
  };
  if (value == null || value <= 0) return null;
  return value;
}

DateTime? parseLeafActionDate(Object? raw) {
  if (raw is! String || raw.trim().isEmpty) return null;
  final text = raw.trim();
  final dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
  if (dateOnly != null) {
    return DateTime(
      int.parse(dateOnly.group(1)!),
      int.parse(dateOnly.group(2)!),
      int.parse(dateOnly.group(3)!),
    );
  }
  return DateTime.tryParse(text);
}

DateTime? _parseDate(Object? raw) => parseLeafActionDate(raw);

String? _joinNoteParts(String? merchant, String? note) {
  final parts = <String>[
    if (merchant != null && merchant.trim().isNotEmpty) merchant.trim(),
    if (note != null && note.trim().isNotEmpty) note.trim(),
  ];
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

SpendLabel? _spendLabelFromWire(String? value) {
  return switch (value) {
    'green' => SpendLabel.green,
    'orange' => SpendLabel.orange,
    'red' => SpendLabel.red,
    _ => null,
  };
}

IncomePostingType? _incomePostingTypeFromWire(String? value) {
  return switch (value) {
    'confirmed_actual' => IncomePostingType.confirmedActual,
    'auto_posted_expected' => IncomePostingType.autoPostedExpected,
    'manual_one_time' => IncomePostingType.manualOneTime,
    _ => null,
  };
}

SavingStyle? _savingStyleFromWire(String? value) {
  return switch (value) {
    'easy' => SavingStyle.easy,
    'natural' => SavingStyle.natural,
    'aggressive' => SavingStyle.aggressive,
    _ => null,
  };
}
