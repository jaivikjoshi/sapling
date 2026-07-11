import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/date_helpers.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/repositories/recurring_income_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../models/enums.dart';

class RecurringIncomeService {
  final RecurringIncomeRepository _repo;
  final TransactionsRepository _txnRepo;
  static const _uuid = Uuid();
  static final _paydayPostLocks = <String, Future<void>>{};

  RecurringIncomeService(this._repo, this._txnRepo);

  Stream<List<RecurringIncome>> watchAll() => _repo.watchAll();

  Future<RecurringIncome> getById(String id) => _repo.getById(id);

  static String? validateAutoPost({
    required PaydayBehavior behavior,
    required double? expectedAmount,
  }) {
    if (behavior == PaydayBehavior.autoPostExpected &&
        (expectedAmount == null || expectedAmount <= 0)) {
      return 'Auto-post requires a positive expected amount.';
    }
    return null;
  }

  static String? validateName(String name) {
    if (name.trim().isEmpty) return 'Name is required.';
    return null;
  }

  Future<String> create({
    required String name,
    required IncomeFrequency frequency,
    required DateTime nextPaydayDate,
    double? expectedAmount,
    required PaydayBehavior paydayBehavior,
    bool isPaydayAnchor = false,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    if (isPaydayAnchor) await _repo.clearPaydayAnchor();

    await _repo.insert(RecurringIncomesCompanion.insert(
      id: id,
      name: name.trim(),
      frequency: Value(enumToDb(frequency)),
      nextPaydayDate: nextPaydayDate,
      expectedAmount: Value(expectedAmount),
      paydayBehavior: Value(enumToDb(paydayBehavior)),
      isPaydayAnchor: Value(isPaydayAnchor),
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }

  Future<void> update({
    required String id,
    required String name,
    required IncomeFrequency frequency,
    required DateTime nextPaydayDate,
    double? expectedAmount,
    required PaydayBehavior paydayBehavior,
  }) async {
    await _repo.updateById(
      id,
      RecurringIncomesCompanion(
        name: Value(name.trim()),
        frequency: Value(enumToDb(frequency)),
        nextPaydayDate: Value(nextPaydayDate),
        expectedAmount: Value(expectedAmount),
        paydayBehavior: Value(enumToDb(paydayBehavior)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) => _repo.deleteById(id);

  Future<void> setPaydayAnchor(String id) => _repo.setPaydayAnchor(id);

  Future<void> clearPaydayAnchor() => _repo.clearPaydayAnchor();

  Future<void> advancePayday(String id) async {
    final income = await _repo.getById(id);
    final freq = enumFromDb<IncomeFrequency>(
      income.frequency,
      IncomeFrequency.values,
    );
    final next = advanceByIncomeFrequency(income.nextPaydayDate, freq);
    await _repo.updateById(
      id,
      RecurringIncomesCompanion(
        nextPaydayDate: Value(next),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  static DateTime computeNextPayday(
    DateTime current,
    IncomeFrequency frequency,
  ) {
    return advanceByIncomeFrequency(current, frequency);
  }

  /// Idempotent payday insert used by [PaydayAutoPoster]. Shares a per-income
  /// lock so overlapping app-open autopost and manual income entry cannot both
  /// pass the existence check.
  Future<bool> postExpectedPaydayIfNeeded({
    required RecurringIncome income,
    required DateTime payday,
    required double amount,
  }) async {
    return _withPaydayPostLock(income.id, () async {
      final paydayDay = DateTime(payday.year, payday.month, payday.day);
      if (await _hasIncomeOnPayday(income.id, paydayDay)) return false;

      final now = DateTime.now();
      await _txnRepo.insert(
        Transaction(
          id: _uuid.v4(),
          type: enumToDb(TransactionType.income),
          amount: amount,
          date: paydayDay,
          incomePostingType: enumToDb(IncomePostingType.autoPostedExpected),
          linkedRecurringIncomeId: income.id,
          note: 'Auto-posted: ${income.name}',
          createdAt: now,
          updatedAt: now,
        ),
      );
      return true;
    });
  }

  Future<bool> _hasIncomeOnPayday(
    String recurringIncomeId,
    DateTime paydayDay,
  ) async {
    final dayEnd = paydayDay.add(const Duration(days: 1));
    final txns = await _txnRepo.getByDateRange(paydayDay, dayEnd);
    return txns.any(
      (t) =>
          t.type == enumToDb(TransactionType.income) &&
          (t.linkedRecurringIncomeId == recurringIncomeId ||
              t.linkedRecurringIncomeId == null),
    );
  }

  Future<T> _withPaydayPostLock<T>(
    String recurringIncomeId,
    Future<T> Function() action,
  ) async {
    final previous = _paydayPostLocks[recurringIncomeId] ?? Future<void>.value();
    final gate = Completer<void>();
    _paydayPostLocks[recurringIncomeId] = gate.future;
    await previous;
    try {
      return await action();
    } finally {
      gate.complete();
      if (identical(_paydayPostLocks[recurringIncomeId], gate.future)) {
        _paydayPostLocks.remove(recurringIncomeId);
      }
    }
  }
}
