import '../../core/utils/date_helpers.dart';
import '../../core/utils/enum_serialization.dart';
import '../models/enums.dart';

class CycleWindow {
  final DateTime start;
  final DateTime end;

  const CycleWindow({required this.start, required this.end});

  int get daysLeft {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final endDay = DateTime(end.year, end.month, end.day);
    final diff = endDay.difference(todayStart).inDays;
    return diff < 1 ? 1 : diff;
  }

  @override
  String toString() => 'CycleWindow($start → $end)';
}

abstract final class CycleWindowCalculator {
  /// Compute the current cycle window for the given [now].
  static CycleWindow compute({
    required RolloverResetType resetType,
    required DateTime now,
    String? anchorFrequency,
    DateTime? anchorNextPaydayDate,
  }) {
    return switch (resetType) {
      RolloverResetType.monthly => _monthly(now),
      RolloverResetType.paydayBased => _paydayBased(
          now,
          anchorFrequency ?? 'monthly',
          anchorNextPaydayDate ?? now,
        ),
    };
  }

  static CycleWindow computeForDate({
    required RolloverResetType resetType,
    required DateTime date,
    String? anchorFrequency,
    DateTime? anchorNextPaydayDate,
  }) {
    return compute(
      resetType: resetType,
      now: date,
      anchorFrequency: anchorFrequency,
      anchorNextPaydayDate: anchorNextPaydayDate,
    );
  }

  static CycleWindow _monthly(DateTime now) {
    final start = DateTime(now.year, now.month);
    final end = (now.month == 12)
        ? DateTime(now.year + 1, 1)
        : DateTime(now.year, now.month + 1);
    return CycleWindow(start: start, end: end);
  }

  /// Payday-based: walk schedule backwards from nextPaydayDate to find
  /// the most recent anchor date <= now, then advance once for end.
  static CycleWindow _paydayBased(
    DateTime now,
    String freqDb,
    DateTime nextPaydayDate,
  ) {
    final freq = enumFromDb<IncomeFrequency>(freqDb, IncomeFrequency.values);
    final nowDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    var cursor = DateTime(
      nextPaydayDate.year,
      nextPaydayDate.month,
      nextPaydayDate.day,
    );

    // Walk forward if cursor is far in the past
    while (advanceByIncomeFrequency(cursor, freq).isBefore(nowDay) ||
        advanceByIncomeFrequency(cursor, freq).isAtSameMomentAs(
            DateTime(now.year, now.month, now.day))) {
      cursor = advanceByIncomeFrequency(cursor, freq);
    }

    // Walk backward if cursor is in the future
    while (cursor.isAfter(nowDay)) {
      cursor = _subtractByFrequency(cursor, freq);
    }

    final cycleStart = DateTime(cursor.year, cursor.month, cursor.day);
    final cycleEnd = advanceByIncomeFrequency(cycleStart, freq);
    return CycleWindow(start: cycleStart, end: cycleEnd);
  }

  static DateTime _subtractByFrequency(DateTime d, IncomeFrequency freq) {
    return switch (freq) {
      IncomeFrequency.weekly =>
        DateTime(d.year, d.month, d.day - 7, d.hour, d.minute, d.second),
      IncomeFrequency.biweekly =>
        DateTime(d.year, d.month, d.day - 14, d.hour, d.minute, d.second),
      IncomeFrequency.monthly => _subtractMonth(d),
    };
  }

  static DateTime _subtractMonth(DateTime d) {
    final prevMonth = d.month == 1 ? 12 : d.month - 1;
    final prevYear = d.month == 1 ? d.year - 1 : d.year;
    final daysInPrev = DateTime(prevYear, prevMonth + 1, 0).day;
    final day = d.day > daysInPrev ? daysInPrev : d.day;
    return DateTime(prevYear, prevMonth, day, d.hour, d.minute, d.second);
  }
}
