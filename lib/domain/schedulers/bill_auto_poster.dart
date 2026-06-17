import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/date_helpers.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../models/enums.dart';

/// Automatically posts an expense transaction for each recurring bill on its
/// due date and rolls the due date forward to the next cycle.
///
/// Runs on every app open (see `LekoApp._runSchedulers`). For each bill whose
/// `nextDueDate` is on or before today, we:
///   1. Insert an expense transaction dated at the due date (idempotent by
///      `linked_bill_id` + date).
///   2. Advance `nextDueDate` by the bill's frequency.
///   3. Repeat until the due date is in the future, so missed cycles are
///      caught up even if the user hasn't opened the app for a while.
class BillAutoPoster {
  final BillsRepository _billsRepo;
  final TransactionsRepository _txnRepo;
  static const _uuid = Uuid();

  BillAutoPoster(this._billsRepo, this._txnRepo);

  /// Posts and advances every autopay bill up to and including [today].
  /// Only processes bills whose [Bill.autopay] flag is true.
  /// Returns the number of expense transactions created across those bills.
  Future<int> runForDate(DateTime today) async {
    final bills = await _billsRepo.getAll();
    final todayStart = DateTime(today.year, today.month, today.day);
    int postedCount = 0;

    for (final bill in bills) {
      if (!bill.autopay) continue;
      postedCount += await _runForBill(bill, todayStart);
    }
    return postedCount;
  }

  Future<int> _runForBill(Bill bill, DateTime todayStart) async {
    final freq = enumFromDb<BillFrequency>(
      bill.frequency,
      BillFrequency.values,
    );
    final label = enumFromDb<SpendLabel>(bill.defaultLabel, SpendLabel.values);

    var due = DateTime(
      bill.nextDueDate.year,
      bill.nextDueDate.month,
      bill.nextDueDate.day,
    );

    int posted = 0;
    // Safety cap in case something looks off — a bill shouldn't advance more
    // than ~1000 cycles in a single catch-up (covers ~83 years of monthly).
    int guard = 0;
    while (!due.isAfter(todayStart) && guard < 1000) {
      guard++;
      final already = await _alreadyPosted(bill.id, due);
      if (!already) {
        await _postExpense(bill, due, label);
        posted++;
      }
      due = advanceByBillFrequency(due, freq);
    }

    if (posted > 0 || due != bill.nextDueDate) {
      await _billsRepo.updateById(
        bill.id,
        BillsCompanion(
          nextDueDate: Value(due),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
    return posted;
  }

  Future<bool> _alreadyPosted(String billId, DateTime dateStart) async {
    final dateEnd = dateStart.add(const Duration(days: 1));
    final txns = await _txnRepo.getByDateRange(dateStart, dateEnd);
    return txns.any(
      (t) =>
          t.type == enumToDb(TransactionType.expense) &&
          t.linkedBillId == billId,
    );
  }

  Future<void> _postExpense(Bill bill, DateTime date, SpendLabel label) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _txnRepo.insert(
      Transaction(
        id: id,
        type: enumToDb(TransactionType.expense),
        amount: bill.amount,
        date: date,
        categoryId: bill.categoryId,
        label: enumToDb(label),
        note: 'Bill auto-posted: ${bill.name}',
        linkedBillId: bill.id,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
