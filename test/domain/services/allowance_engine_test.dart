import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leko/data/db/leko_database.dart';
import 'package:leko/data/repositories/bills_repository.dart';
import 'package:leko/data/repositories/goals_repository.dart';
import 'package:leko/data/repositories/recurring_income_repository.dart';
import 'package:leko/data/repositories/transactions_repository.dart';
import 'package:leko/domain/models/enums.dart';
import 'package:leko/domain/models/settings_model.dart';
import 'package:leko/domain/services/allowance_engine.dart';
import 'package:leko/domain/services/ledger_service.dart';

void main() {
  late LekoDatabase db;
  late TransactionsRepository txnRepo;
  late BillsRepository billsRepo;
  late RecurringIncomeRepository incomeRepo;
  late GoalsRepository goalsRepo;
  late AllowanceEngine engine;
  late LedgerService ledger;

  setUp(() {
    db = LekoDatabase.forTesting(NativeDatabase.memory());
    txnRepo = DriftTransactionsRepository(db);
    billsRepo = DriftBillsRepository(db);
    incomeRepo = DriftRecurringIncomeRepository(db);
    goalsRepo = DriftGoalsRepository(db);
    engine = AllowanceEngine(txnRepo, billsRepo, incomeRepo, goalsRepo);
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
      expect(result.dailyAllowance, 0);
      expect(result.todaySpend, 0);
      expect(result.remainingToday, 0);
      expect(result.behindAmount, 0);
      expect(result.daysLeft, greaterThan(0));
    });

    test('income creates daily allowance = balance / daysLeft', () async {
      await ledger.addIncome(
        amount: 3000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );

      final result =
          await engine.computePaycheckMode(settings: baseSettings);
      expect(result.balance, 3000);
      // dailyAllowance = spendablePool / daysLeft = 3000 / daysLeft
      expect(result.dailyAllowance, closeTo(3000 / result.daysLeft, 0.01));
      expect(result.todaySpend, 0);
      expect(result.remainingToday, result.dailyAllowance);
    });

    test('today spend reduces remaining but not daily allowance', () async {
      await ledger.addIncome(
        amount: 3000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );
      await ledger.addExpense(
        amount: 50,
        date: DateTime.now(),
        categoryId: 'cat-1',
        label: SpendLabel.green,
      );

      final result =
          await engine.computePaycheckMode(settings: baseSettings);
      expect(result.balance, 2950);
      expect(result.todaySpend, 50);
      // remainingToday = dailyAllowance - 50
      expect(result.remainingToday, result.dailyAllowance - 50);
    });

    test('overspend yesterday naturally tightens today', () async {
      final now = DateTime.now();
      // Add income yesterday
      await ledger.addIncome(
        amount: 1000,
        date: DateTime(now.year, now.month, now.day - 1),
        postingType: IncomePostingType.manualOneTime,
      );
      // Overspend yesterday (more than daily would be)
      await ledger.addExpense(
        amount: 200,
        date: DateTime(now.year, now.month, now.day - 1),
        categoryId: 'cat-1',
        label: SpendLabel.red,
      );

      final result =
          await engine.computePaycheckMode(settings: baseSettings);
      // Balance = 800, daily = 800/daysLeft
      expect(result.balance, 800);
      expect(result.dailyAllowance, closeTo(800 / result.daysLeft, 0.01));
      // The overspend is naturally carried forward via the reduced balance
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
      // spendable = 3000 - 1000 = 2000
      expect(result.projectedBills, greaterThanOrEqualTo(1000));
      expect(result.spendablePool, closeTo(2000, 1));
    });

    test('behind amount is positive when overspent overall', () async {
      await ledger.addExpense(
        amount: 500,
        date: DateTime.now(),
        categoryId: 'cat-1',
        label: SpendLabel.red,
      );

      final result =
          await engine.computePaycheckMode(settings: baseSettings);
      expect(result.balance, -500);
      expect(result.dailyAllowance, 0);
      expect(result.behindAmount, 500);
    });
  });

  group('AllowanceEngine — payday_based cycle', () {
    test('uses anchor schedule for cycle boundaries', () async {
      final now = DateTime.now();
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
      final cycleDays = result.cycleWindow.end
          .difference(result.cycleWindow.start)
          .inDays;
      // Biweekly = ~14 days (may be 13 due to day boundary)
      expect(cycleDays, inInclusiveRange(13, 14));
    });
  });
}
