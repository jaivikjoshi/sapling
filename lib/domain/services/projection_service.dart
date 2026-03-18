import '../../core/utils/date_helpers.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../models/enums.dart';

/// Projects future income and bills into a window [start, end).
abstract final class ProjectionService {
  /// Sum projected income for [start, end).
  /// Includes confirmed income transactions in the window plus
  /// future scheduled paydays.
  static double projectIncome({
    required DateTime start,
    required DateTime end,
    required List<Transaction> confirmedIncome,
    required List<RecurringIncome> schedules,
  }) {
    double total = 0;

    for (final txn in confirmedIncome) {
      if (!txn.date.isBefore(start) && txn.date.isBefore(end)) {
        total += txn.amount;
      }
    }

    for (final schedule in schedules) {
      final freq =
          enumFromDb<IncomeFrequency>(schedule.frequency, IncomeFrequency.values);
      final behavior =
          enumFromDb<PaydayBehavior>(schedule.paydayBehavior, PaydayBehavior.values);

      var cursor = DateTime(
        schedule.nextPaydayDate.year,
        schedule.nextPaydayDate.month,
        schedule.nextPaydayDate.day,
      );

      while (cursor.isBefore(end)) {
        if (!cursor.isBefore(start)) {
          final isAlreadyConfirmed = confirmedIncome.any((t) =>
              t.linkedRecurringIncomeId == schedule.id &&
              _sameDay(t.date, cursor));

          if (!isAlreadyConfirmed) {
            if (behavior == PaydayBehavior.autoPostExpected &&
                schedule.expectedAmount != null) {
              total += schedule.expectedAmount!;
            } else if (behavior == PaydayBehavior.confirmActualOnPayday &&
                schedule.expectedAmount != null) {
              total += schedule.expectedAmount!;
            }
            // If no expectedAmount, conservative = 0
          }
        }
        cursor = advanceByIncomeFrequency(cursor, freq);
      }
    }

    return total;
  }

  /// Sum planned bills due in [start, end) that are not yet paid.
  /// A bill instance is "unpaid" if its nextDueDate is in the window.
  /// Simulates due dates forward from each bill's nextDueDate.
  static double projectBills({
    required DateTime start,
    required DateTime end,
    required List<Bill> bills,
    required List<Transaction> paidBillTransactions,
  }) {
    double total = 0;

    for (final bill in bills) {
      final freq =
          enumFromDb<BillFrequency>(bill.frequency, BillFrequency.values);
      var cursor = DateTime(
        bill.nextDueDate.year,
        bill.nextDueDate.month,
        bill.nextDueDate.day,
      );

      while (cursor.isBefore(end)) {
        if (!cursor.isBefore(start)) {
          final alreadyPaid = paidBillTransactions.any((t) =>
              t.linkedBillId == bill.id && _sameDay(t.date, cursor));

          if (!alreadyPaid) {
            total += bill.amount;
          }
        }
        cursor = advanceByBillFrequency(cursor, freq);
      }
    }

    return total;
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
