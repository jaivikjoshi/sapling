import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/data/db/sapling_database.dart';
import 'package:sapling/domain/services/projection_service.dart';

void main() {

  group('ProjectionService.projectIncome', () {
    test('counts confirmed income in window', () {
      final txns = [
        _fakeTxn(type: 'income', amount: 2000, date: DateTime(2025, 6, 15)),
        _fakeTxn(type: 'income', amount: 500, date: DateTime(2025, 6, 20)),
      ];

      final total = ProjectionService.projectIncome(
        start: DateTime(2025, 6, 1),
        end: DateTime(2025, 7, 1),
        confirmedIncome: txns,
        schedules: [],
      );
      expect(total, 2500);
    });

    test('excludes income outside window', () {
      final txns = [
        _fakeTxn(type: 'income', amount: 1000, date: DateTime(2025, 5, 31)),
        _fakeTxn(type: 'income', amount: 500, date: DateTime(2025, 7, 1)),
      ];

      final total = ProjectionService.projectIncome(
        start: DateTime(2025, 6, 1),
        end: DateTime(2025, 7, 1),
        confirmedIncome: txns,
        schedules: [],
      );
      expect(total, 0);
    });

    test('adds projected schedule paydays in window', () {
      final schedules = [
        _fakeIncome(
          nextPaydayDate: DateTime(2025, 6, 15),
          frequency: 'biweekly',
          expectedAmount: 1500,
          behavior: 'auto_post_expected',
        ),
      ];

      final total = ProjectionService.projectIncome(
        start: DateTime(2025, 6, 1),
        end: DateTime(2025, 7, 1),
        confirmedIncome: [],
        schedules: schedules,
      );
      // June 15 and June 29 are in window
      expect(total, 3000);
    });

    test('does not double-count confirmed + projected', () {
      final schedules = [
        _fakeIncome(
          id: 'sched-1',
          nextPaydayDate: DateTime(2025, 6, 15),
          frequency: 'monthly',
          expectedAmount: 2000,
          behavior: 'confirm_actual_on_payday',
        ),
      ];

      final confirmedTxns = [
        _fakeTxn(
          type: 'income',
          amount: 2100,
          date: DateTime(2025, 6, 15),
          linkedRecurringIncomeId: 'sched-1',
        ),
      ];

      final total = ProjectionService.projectIncome(
        start: DateTime(2025, 6, 1),
        end: DateTime(2025, 7, 1),
        confirmedIncome: confirmedTxns,
        schedules: schedules,
      );
      // Confirmed 2100, projected skipped because same day + same schedule
      expect(total, 2100);
    });
  });

  group('ProjectionService.projectBills', () {
    test('counts unpaid bills in window', () {
      final bills = [
        _fakeBill(
          nextDueDate: DateTime(2025, 6, 10),
          amount: 100,
          frequency: 'monthly',
        ),
      ];

      final total = ProjectionService.projectBills(
        start: DateTime(2025, 6, 1),
        end: DateTime(2025, 7, 1),
        bills: bills,
        paidBillTransactions: [],
      );
      expect(total, 100);
    });

    test('excludes bills outside window', () {
      final bills = [
        _fakeBill(
          nextDueDate: DateTime(2025, 7, 10),
          amount: 200,
          frequency: 'monthly',
        ),
      ];

      final total = ProjectionService.projectBills(
        start: DateTime(2025, 6, 1),
        end: DateTime(2025, 7, 1),
        bills: bills,
        paidBillTransactions: [],
      );
      expect(total, 0);
    });

    test('weekly bill generates multiple instances in window', () {
      final bills = [
        _fakeBill(
          nextDueDate: DateTime(2025, 6, 1),
          amount: 50,
          frequency: 'weekly',
        ),
      ];

      final total = ProjectionService.projectBills(
        start: DateTime(2025, 6, 1),
        end: DateTime(2025, 7, 1),
        bills: bills,
        paidBillTransactions: [],
      );
      // June 1, 8, 15, 22, 29 = 5 instances
      expect(total, 250);
    });
  });
}

// Helpers to build fake Drift data objects for pure projection testing.

Transaction _fakeTxn({
  String id = '',
  required String type,
  required double amount,
  required DateTime date,
  String? linkedRecurringIncomeId,
  String? linkedBillId,
}) {
  return Transaction(
    id: id.isEmpty ? 'txn-${date.millisecondsSinceEpoch}' : id,
    type: type,
    amount: amount,
    date: date,
    categoryId: null,
    label: null,
    note: null,
    linkedBillId: linkedBillId,
    linkedRecurringIncomeId: linkedRecurringIncomeId,
    linkedSplitEntryId: null,
    incomePostingType: null,
    source: null,
    createdAt: date,
    updatedAt: date,
  );
}

RecurringIncome _fakeIncome({
  String id = 'income-1',
  required DateTime nextPaydayDate,
  required String frequency,
  double? expectedAmount,
  required String behavior,
}) {
  return RecurringIncome(
    id: id,
    name: 'Test Income',
    frequency: frequency,
    nextPaydayDate: nextPaydayDate,
    expectedAmount: expectedAmount,
    paydayBehavior: behavior,
    isPaydayAnchorEligible: true,
    isPaydayAnchor: false,
    reminderEnabled: false,
    reminderTime: null,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

Bill _fakeBill({
  String id = 'bill-1',
  required DateTime nextDueDate,
  required double amount,
  required String frequency,
}) {
  return Bill(
    id: id,
    name: 'Test Bill',
    amount: amount,
    frequency: frequency,
    nextDueDate: nextDueDate,
    categoryId: 'cat-1',
    defaultLabel: 'green',
    autopay: false,
    reminderEnabled: true,
    reminderLeadTimeDays: 3,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}
