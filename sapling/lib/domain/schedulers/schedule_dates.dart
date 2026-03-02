import '../../data/db/sapling_database.dart';
import '../models/enums.dart';

/// Pure helpers for next scheduling dates. Used by NotificationSchedulerImpl and tests.
abstract final class ScheduleDates {
  /// Next payday reminder: on payday at reminder time, or 9:00 if not set.
  static DateTime nextPaydayReminderTime(RecurringIncome income, DateTime now) {
    final payday = DateTime(
      income.nextPaydayDate.year,
      income.nextPaydayDate.month,
      income.nextPaydayDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    if (payday.isBefore(today)) return now; // past; caller may advance
    final hour = 9;
    final minute = 0;
    if (income.reminderTime != null && income.reminderTime!.isNotEmpty) {
      final parts = income.reminderTime!.split(':');
      final h = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 9 : 9;
      final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      return DateTime(payday.year, payday.month, payday.day, h, m);
    }
    return DateTime(payday.year, payday.month, payday.day, hour, minute);
  }

  /// Bill reminder: nextDueDate minus reminderLeadTimeDays at 9:00.
  static DateTime nextBillReminderTime(Bill bill, DateTime now) {
    final due = DateTime(
      bill.nextDueDate.year,
      bill.nextDueDate.month,
      bill.nextDueDate.day,
    );
    final lead = bill.reminderLeadTimeDays;
    final reminderDay = DateTime(due.year, due.month, due.day - lead);
    return DateTime(
      reminderDay.year,
      reminderDay.month,
      reminderDay.day,
      9,
      0,
    );
  }

  /// Whether a payday reminder should fire on or before [when] for this income.
  static bool isPaydayReminderDue(RecurringIncome income, DateTime when) {
    final scheduled = nextPaydayReminderTime(income, when);
    final payday = DateTime(
      income.nextPaydayDate.year,
      income.nextPaydayDate.month,
      income.nextPaydayDate.day,
    );
    final whenDay = DateTime(when.year, when.month, when.day);
    return !payday.isAfter(whenDay) && !scheduled.isAfter(when);
  }

  /// Whether a bill reminder should fire on or before [when].
  static bool isBillReminderDue(Bill bill, DateTime when) {
    final scheduled = nextBillReminderTime(bill, when);
    return !scheduled.isAfter(when);
  }

  /// Parse "HH:mm" and return next occurrence in local date from [dateStart].
  static DateTime nextDailyAt(String timeString, DateTime dateStart) {
    final parts = timeString.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 21 : 21;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    var at = DateTime(
      dateStart.year,
      dateStart.month,
      dateStart.day,
      hour,
      minute,
    );
    if (at.isBefore(dateStart)) {
      at = DateTime(
        dateStart.year,
        dateStart.month,
        dateStart.day + 1,
        hour,
        minute,
      );
    }
    return at;
  }
}
