import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/enum_serialization.dart';
import '../../data/db/sapling_database.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../domain/models/enums.dart';

class LedgerService {
  final TransactionsRepository _repo;
  static const _uuid = Uuid();

  LedgerService(this._repo);

  Future<String> addExpense({
    required double amount,
    required DateTime date,
    required String categoryId,
    required SpendLabel label,
    String? note,
    String? linkedBillId,
    String? linkedSplitEntryId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _repo.insert(TransactionsCompanion.insert(
      id: id,
      type: enumToDb(TransactionType.expense),
      amount: amount,
      date: date,
      categoryId: Value(categoryId),
      label: Value(enumToDb(label)),
      note: Value(note),
      linkedBillId: Value(linkedBillId),
      linkedSplitEntryId: Value(linkedSplitEntryId),
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }

  Future<String> addIncome({
    required double amount,
    required DateTime date,
    required IncomePostingType postingType,
    String? source,
    String? note,
    String? linkedRecurringIncomeId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _repo.insert(TransactionsCompanion.insert(
      id: id,
      type: enumToDb(TransactionType.income),
      amount: amount,
      date: date,
      source: Value(source),
      incomePostingType: Value(enumToDb(postingType)),
      note: Value(note),
      linkedRecurringIncomeId: Value(linkedRecurringIncomeId),
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }

  Future<String> addAdjustment({
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _repo.insert(TransactionsCompanion.insert(
      id: id,
      type: enumToDb(TransactionType.adjustment),
      amount: amount,
      date: date,
      note: Value(note),
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }

  Future<double> computeBalance() => _repo.computeBalance();

  Stream<double> watchBalance() => _repo.watchBalance();

  Future<String> reconcile(double realBalance) async {
    final current = await computeBalance();
    final adjustment = realBalance - current;
    return addAdjustment(
      amount: adjustment,
      date: DateTime.now(),
      note: 'Reconcile to bank balance',
    );
  }

  Future<void> updateExpense({
    required String id,
    double? amount,
    DateTime? date,
    String? categoryId,
    SpendLabel? label,
    String? note,
  }) async {
    final now = DateTime.now();
    final c = TransactionsCompanion(
      updatedAt: Value(now),
      amount: amount != null ? Value(amount) : const Value.absent(),
      date: date != null ? Value(date) : const Value.absent(),
      categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
      label: label != null ? Value(enumToDb(label)) : const Value.absent(),
      note: note != null ? Value(note) : const Value.absent(),
    );
    await _repo.updateById(id, c);
  }

  Future<Transaction?> getTransactionById(String id) async {
    try {
      return await _repo.getById(id);
    } catch (_) {
      return null;
    }
  }

  Stream<List<Transaction>> watchRecent({int limit = 50}) {
    return _repo.watchAll(limit: limit);
  }

  Stream<List<Transaction>> watchByDateRange(DateTime start, DateTime end) {
    return _repo.watchByDateRange(start, end);
  }
}
