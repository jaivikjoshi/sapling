import 'package:flutter_test/flutter_test.dart';

import 'package:leko/data/db/leko_database.dart';
import 'package:leko/domain/schedulers/schedule_dates.dart';

RecurringIncome _income({
  String id = '1',
  DateTime? nextPaydayDate,
  bool reminderEnabled = true,
  String? reminderTime,
}) {
  return RecurringIncome(
    id: id,
    name: 'Job',
    frequency: 'monthly',
    nextPaydayDate: nextPaydayDate ?? DateTime(2025, 6, 15),
    expectedAmount: 3000,
    paydayBehavior: 'confirm_actual_on_payday',
    isPaydayAnchorEligible: true,
    isPaydayAnchor: false,
    reminderEnabled: reminderEnabled,
    reminderTime: reminderTime,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

Bill _bill({
  DateTime? nextDueDate,
  int reminderLeadTimeDays = 3,
}) {
  return Bill(
    id: '1',
    name: 'Rent',
    amount: 1000,
    frequency: 'monthly',
    nextDueDate: nextDueDate ?? DateTime(2025, 6, 10),
    categoryId: 'cat_rent',
    defaultLabel: 'green',
    autopay: false,
    reminderEnabled: true,
    reminderLeadTimeDays: reminderLeadTimeDays,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

void main() {
  group('ScheduleDates', () {
    group('nextPaydayReminderTime', () {
      test('uses reminder time when set', () {
        final income = _income(reminderTime: '08:30');
        final at = ScheduleDates.nextPaydayReminderTime(
          income,
          DateTime(2025, 6, 1),
        );
        expect(at.year, 2025);
        expect(at.month, 6);
        expect(at.day, 15);
        expect(at.hour, 8);
        expect(at.minute, 30);
      });

      test('defaults to 9:00 when reminder time not set', () {
        final income = _income(reminderTime: null);
        final at = ScheduleDates.nextPaydayReminderTime(
          income,
          DateTime(2025, 6, 1),
        );
        expect(at.hour, 9);
        expect(at.minute, 0);
      });
    });

    group('nextBillReminderTime', () {
      test('is lead days before due at 9:00', () {
        final bill = _bill();
        final at = ScheduleDates.nextBillReminderTime(
          bill,
          DateTime(2025, 6, 1),
        );
        expect(at.year, 2025);
        expect(at.month, 6);
        expect(at.day, 7);
        expect(at.hour, 9);
        expect(at.minute, 0);
      });
    });

    group('nextDailyAt', () {
      test('returns same day when time is after dateStart', () {
        final at = ScheduleDates.nextDailyAt(
          '21:00',
          DateTime(2025, 6, 15, 10, 0),
        );
        expect(at.year, 2025);
        expect(at.month, 6);
        expect(at.day, 15);
        expect(at.hour, 21);
        expect(at.minute, 0);
      });

      test('returns next day when time is before dateStart', () {
        final at = ScheduleDates.nextDailyAt(
          '09:00',
          DateTime(2025, 6, 15, 12, 0),
        );
        expect(at.day, 16);
        expect(at.hour, 9);
      });
    });
  });
}
