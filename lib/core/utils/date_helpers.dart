import '../../domain/models/enums.dart';

DateTime advanceByIncomeFrequency(DateTime date, IncomeFrequency frequency) {
  return switch (frequency) {
    IncomeFrequency.weekly => _addDays(date, 7),
    IncomeFrequency.biweekly => _addDays(date, 14),
    IncomeFrequency.monthly => _addMonths(date, 1),
  };
}

DateTime advanceByBillFrequency(DateTime date, BillFrequency frequency) {
  return switch (frequency) {
    BillFrequency.weekly => _addDays(date, 7),
    BillFrequency.biweekly => _addDays(date, 14),
    BillFrequency.monthly => _addMonths(date, 1),
    BillFrequency.quarterly => _addMonths(date, 3),
    BillFrequency.yearly => _addMonths(date, 12),
  };
}

DateTime _addDays(DateTime d, int days) {
  return DateTime(d.year, d.month, d.day + days, d.hour, d.minute, d.second);
}

DateTime _addMonths(DateTime d, int months) {
  var totalMonths = d.year * 12 + (d.month - 1) + months;
  final nextYear = totalMonths ~/ 12;
  final nextMonth = totalMonths % 12 + 1;
  final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
  final day = d.day > daysInNextMonth ? daysInNextMonth : d.day;
  return DateTime(nextYear, nextMonth, day, d.hour, d.minute, d.second);
}
