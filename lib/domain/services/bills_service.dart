import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/date_helpers.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../models/enums.dart';

class BillsService {
  final BillsRepository _billsRepo;
  final TransactionsRepository _txnRepo;
  static const _uuid = Uuid();

  BillsService(this._billsRepo, this._txnRepo);

  Stream<List<Bill>> watchAll() => _billsRepo.watchAll();

  Stream<List<Bill>> watchUpcoming({int days = 30}) =>
      _billsRepo.watchUpcoming(days: days);

  Future<Bill> getById(String id) => _billsRepo.getById(id);

  static String? validateName(String name) {
    if (name.trim().isEmpty) return 'Name is required.';
    return null;
  }

  static String? validateAmount(double? amount) {
    if (amount == null || amount <= 0) return 'Amount must be greater than 0.';
    return null;
  }

  Future<String> create({
    required String name,
    required double amount,
    required BillFrequency frequency,
    required DateTime nextDueDate,
    required String categoryId,
    required SpendLabel defaultLabel,
    bool autopay = false,
    bool reminderEnabled = true,
    int reminderLeadTimeDays = 3,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _billsRepo.insert(
      BillsCompanion.insert(
        id: id,
        name: name.trim(),
        amount: amount,
        frequency: Value(enumToDb(frequency)),
        nextDueDate: nextDueDate,
        categoryId: categoryId,
        defaultLabel: Value(enumToDb(defaultLabel)),
        autopay: Value(autopay),
        reminderEnabled: Value(reminderEnabled),
        reminderLeadTimeDays: Value(reminderLeadTimeDays),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  Future<void> update({
    required String id,
    required String name,
    required double amount,
    required BillFrequency frequency,
    required DateTime nextDueDate,
    required String categoryId,
    required SpendLabel defaultLabel,
    bool? autopay,
    bool? reminderEnabled,
    int? reminderLeadTimeDays,
  }) async {
    await _billsRepo.updateById(
      id,
      BillsCompanion(
        name: Value(name.trim()),
        amount: Value(amount),
        frequency: Value(enumToDb(frequency)),
        nextDueDate: Value(nextDueDate),
        categoryId: Value(categoryId),
        defaultLabel: Value(enumToDb(defaultLabel)),
        autopay: autopay != null ? Value(autopay) : const Value.absent(),
        reminderEnabled:
            reminderEnabled != null
                ? Value(reminderEnabled)
                : const Value.absent(),
        reminderLeadTimeDays:
            reminderLeadTimeDays != null
                ? Value(reminderLeadTimeDays)
                : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) => _billsRepo.deleteById(id);

  /// Canonical Mark Paid: creates expense transaction, advances nextDueDate.
  ///
  /// If an expense for this bill already exists on the paid day (for example
  /// from [BillAutoPoster]), this call is a no-op for the ledger and schedule:
  /// it returns that transaction without inserting a duplicate or advancing
  /// [nextDueDate] again.
  Future<MarkPaidResult> markPaid({
    required String billId,
    DateTime? paidDate,
    double? amountOverride,
  }) async {
    final bill = await _billsRepo.getById(billId);
    final effectiveDate = paidDate ?? DateTime.now();
    final effectiveAmount = amountOverride ?? bill.amount;
    final label = enumFromDb<SpendLabel>(bill.defaultLabel, SpendLabel.values);

    final existing = await _findLinkedExpenseInCurrentCycle(
      bill,
      effectiveDate: effectiveDate,
    );
    if (existing != null) {
      return MarkPaidResult(
        transactionId: existing.id,
        updatedBill: bill,
        paidAmount: existing.amount,
      );
    }

    final txnId = _uuid.v4();
    final now = DateTime.now();
    await _txnRepo.insert(
      Transaction(
        id: txnId,
        type: enumToDb(TransactionType.expense),
        amount: effectiveAmount,
        date: effectiveDate,
        categoryId: bill.categoryId,
        label: enumToDb(label),
        note: 'Bill paid: ${bill.name}',
        linkedBillId: billId,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final freq = enumFromDb<BillFrequency>(
      bill.frequency,
      BillFrequency.values,
    );
    final nextDue = advanceByBillFrequency(bill.nextDueDate, freq);
    await _billsRepo.updateById(
      billId,
      BillsCompanion(nextDueDate: Value(nextDue), updatedAt: Value(now)),
    );

    final updated = await _billsRepo.getById(billId);
    return MarkPaidResult(
      transactionId: txnId,
      updatedBill: updated,
      paidAmount: effectiveAmount,
    );
  }

  static DateTime computeNextDueDate(
    DateTime current,
    BillFrequency frequency,
  ) {
    return advanceByBillFrequency(current, frequency);
  }

  Future<Transaction?> _findLinkedExpenseInCurrentCycle(
    Bill bill, {
    required DateTime effectiveDate,
  }) async {
    final freq = enumFromDb<BillFrequency>(
      bill.frequency,
      BillFrequency.values,
    );
    final dueDay = DateTime(
      bill.nextDueDate.year,
      bill.nextDueDate.month,
      bill.nextDueDate.day,
    );
    final paidDay = DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
    );

    for (final day in {paidDay, dueDay}) {
      final match = await _findLinkedExpenseOnDay(bill.id, day);
      if (match != null) return match;
    }

    // When confirming before the due date, treat any linked payment in the
    // current billing window as satisfying markPaid (e.g. autopay on the 1st,
    // user taps Mark Paid on the 3rd while nextDueDate already advanced).
    if (paidDay.isBefore(dueDay)) {
      final cycleStart = retreatByBillFrequency(dueDay, freq);
      final cycleEnd = dueDay.add(const Duration(days: 1));
      final cycleTxns = await _txnRepo.getByDateRange(cycleStart, cycleEnd);
      for (final t in cycleTxns) {
        if (t.type == enumToDb(TransactionType.expense) &&
            t.linkedBillId == bill.id) {
          return t;
        }
      }
    }

    return null;
  }

  Future<Transaction?> _findLinkedExpenseOnDay(
    String billId,
    DateTime day,
  ) async {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final dayTxns = await _txnRepo.getByDateRange(dayStart, dayEnd);
    for (final t in dayTxns) {
      if (t.type == enumToDb(TransactionType.expense) &&
          t.linkedBillId == billId) {
        return t;
      }
    }
    return null;
  }
}

class MarkPaidResult {
  final String transactionId;
  final Bill updatedBill;
  final double paidAmount;

  const MarkPaidResult({
    required this.transactionId,
    required this.updatedBill,
    required this.paidAmount,
  });
}
