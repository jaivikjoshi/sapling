import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
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
    await _repo.insert(Transaction(
      id: id,
      type: enumToDb(TransactionType.expense),
      amount: amount,
      date: date,
      categoryId: categoryId,
      label: enumToDb(label),
      note: note,
      linkedBillId: linkedBillId,
      linkedSplitEntryId: linkedSplitEntryId,
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
    await _repo.insert(Transaction(
      id: id,
      type: enumToDb(TransactionType.income),
      amount: amount,
      date: date,
      source: source,
      incomePostingType: enumToDb(postingType),
      note: note,
      linkedRecurringIncomeId: linkedRecurringIncomeId,
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
    await _repo.insert(Transaction(
      id: id,
      type: enumToDb(TransactionType.adjustment),
      amount: amount,
      date: date,
      note: note,
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
    final existing = await _repo.getByIdOrNull(id);
    if (existing == null) return;
    final now = DateTime.now();
    await _repo.updateById(
      id,
      existing.copyWith(
        amount: amount ?? existing.amount,
        date: date ?? existing.date,
        categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
        label: label != null ? Value(enumToDb(label)) : const Value.absent(),
        note: note != null ? Value(note) : const Value.absent(),
        updatedAt: now,
      ),
    );
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
