import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/data/db/sapling_database.dart';
import 'package:sapling/data/repositories/bills_repository.dart';
import 'package:sapling/data/repositories/recurring_income_repository.dart';
import 'package:sapling/data/repositories/transactions_repository.dart';
import 'package:sapling/domain/models/enums.dart';
import 'package:sapling/domain/models/settings_model.dart';
import 'package:sapling/domain/services/allowance_engine.dart';
import 'package:sapling/domain/services/ledger_service.dart';

void main() {
  late SaplingDatabase db;
  late TransactionsRepository txnRepo;
  late BillsRepository billsRepo;
  late RecurringIncomeRepository incomeRepo;
  late AllowanceEngine engine;
  late LedgerService ledger;

  setUp(() {
    db = SaplingDatabase.forTesting(NativeDatabase.memory());
    txnRepo = TransactionsRepository(db);
    billsRepo = BillsRepository(db);
    incomeRepo = RecurringIncomeRepository(db);
    engine = AllowanceEngine(txnRepo, billsRepo, incomeRepo, null);
    ledger = LedgerService(txnRepo);
  });

  tearDown(() => db.close());

  final baseSettings = UserSettings.defaults.copyWith(
    rolloverResetType: RolloverResetType.monthly,
    onboardingCompleted: true,
  );

  group('AllowanceEngine — paycheck mode (monthly)', () {
    test('empty state returns zero allowance', () async {
      final result =
          await engine.computePaycheckMode(settings: baseSettings);
      expect(result.balance, 0);
      expect(result.allowanceToday, 0);
      expect(result.behindAmount, 0);
      expect(result.daysLeft, greaterThan(0));
    });

    test('income increases available allowance', () async {
      await ledger.addIncome(
        amount: 3000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );

      final result =
          await engine.computePaycheckMode(settings: baseSettings);
      expect(result.balance, 3000);
      expect(result.allowanceToday, greaterThan(0));
    });

    test('expense reduces balance and affects allowance', () async {
      await ledger.addIncome(
        amount: 3000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );
      await ledger.addExpense(
        amount: 1000,
        date: DateTime.now(),
        categoryId: 'cat-1',
        label: SpendLabel.green,
      );

      final result =
          await engine.computePaycheckMode(settings: baseSettings);
      expect(result.balance, 2000);
    });

    test('planned bills reduce projected available', () async {
      await ledger.addIncome(
        amount: 3000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );

      final now = DateTime.now();
      final dueDate = DateTime(now.year, now.month, now.day + 5);
      await billsRepo.insert(BillsCompanion.insert(
        id: 'bill-test',
        name: 'Rent',
        amount: 1000,
        nextDueDate: dueDate,
        categoryId: 'cat-1',
        createdAt: now,
        updatedAt: now,
      ));

      final result =
          await engine.computePaycheckMode(settings: baseSettings);
      // Balance is 3000, but 1000 in bills reduces the available pool
      expect(result.projectedBills, greaterThanOrEqualTo(1000));
    });

    test('behind amount is positive when overspent', () async {
      // Start with 0 balance, add an expense -> negative balance
      await ledger.addExpense(
        amount: 500,
        date: DateTime.now(),
        categoryId: 'cat-1',
        label: SpendLabel.red,
      );

      final result =
          await engine.computePaycheckMode(settings: baseSettings);
      expect(result.balance, -500);
      expect(result.allowanceToday, 0);
      expect(result.behindAmount, greaterThan(0));
    });
  });

  group('AllowanceEngine — payday_based cycle', () {
    test('uses anchor schedule for cycle boundaries', () async {
      final now = DateTime.now();
      // Create an anchor income that pays biweekly
      await incomeRepo.insert(RecurringIncomesCompanion.insert(
        id: 'anchor-1',
        name: 'Salary',
        frequency: const Value('biweekly'),
        nextPaydayDate: DateTime(now.year, now.month, now.day + 7),
        expectedAmount: const Value(2000),
        isPaydayAnchor: const Value(true),
        createdAt: now,
        updatedAt: now,
      ));

      await ledger.addIncome(
        amount: 2000,
        date: now,
        postingType: IncomePostingType.manualOneTime,
      );

      final paydaySettings = baseSettings.copyWith(
        rolloverResetType: RolloverResetType.paydayBased,
        paydayAnchorRecurringIncomeId: () => 'anchor-1',
      );

      final result =
          await engine.computePaycheckMode(settings: paydaySettings);
      expect(result.cycleWindow.start.year, greaterThan(0));
      expect(result.cycleWindow.end.year, greaterThan(0));
      // Cycle should be ~14 days for biweekly
      final cycleDays = result.cycleWindow.end
          .difference(result.cycleWindow.start)
          .inDays;
      expect(cycleDays, 14);
    });
  });
}
