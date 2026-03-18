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

  Future<String> createGoal({
    double amount = 5000,
    int daysFromNow = 90,
    String style = 'natural',
    String id = 'goal-1',
  }) async {
    final now = DateTime.now();
    await goalsRepo.insert(GoalsCompanion.insert(
      id: id,
      name: 'Test Goal',
      targetAmount: amount,
      targetDate: DateTime(now.year, now.month, now.day + daysFromNow),
      savingStyle: Value(style),
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }

  UserSettings settingsWithGoal(String goalId) =>
      UserSettings.defaults.copyWith(
        rolloverResetType: RolloverResetType.monthly,
        onboardingCompleted: true,
        primaryGoalId: () => goalId,
      );

  group('AllowanceEngine — goal mode', () {
    test('returns null when no primary goal set', () async {
      final result = await engine.computeGoalMode(
        settings: UserSettings.defaults,
      );
      expect(result, equals(null));
    });

    test('goal mode: daily = (balance + income - bills - goalTarget) / days',
        () async {
      // Balance = $5000, goal target = $2000, 90 days to goal
      // No future income or bills → spendable = 5000 - 2000 = 3000
      // dailyAllowance = 3000 / 91 ≈ $32.97
      final goalId = await createGoal(amount: 2000, daysFromNow: 90);
      await ledger.addIncome(
        amount: 5000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );

      final result = await engine.computeGoalMode(
        settings: settingsWithGoal(goalId),
      );

      expect(result, isNot(equals(null)));
      expect(result!.balance, 5000);
      expect(result.spendablePool, closeTo(3000, 1));
      // daysToGoal = 91 (90 + 1 for today)
      expect(result.dailyAllowance, closeTo(3000 / 91, 0.5));
      expect(result.todaySpend, 0);
      expect(result.remainingToday, result.dailyAllowance);
    });

    test('today spend reduces remaining in goal mode', () async {
      final goalId = await createGoal(amount: 2000, daysFromNow: 60);
      await ledger.addIncome(
        amount: 5000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );
      await ledger.addExpense(
        amount: 20,
        date: DateTime.now(),
        categoryId: 'cat-1',
        label: SpendLabel.green,
      );

      final result = await engine.computeGoalMode(
        settings: settingsWithGoal(goalId),
      );

      expect(result, isNot(equals(null)));
      expect(result!.todaySpend, 20);
      expect(result.remainingToday, result.dailyAllowance - 20);
    });

    test('saving style does not affect daily spend (pure cash flow)',
        () async {
      await ledger.addIncome(
        amount: 10000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );

      await createGoal(
        id: 'easy-goal',
        amount: 2000,
        daysFromNow: 60,
        style: 'easy',
      );
      await createGoal(
        id: 'aggro-goal',
        amount: 2000,
        daysFromNow: 60,
        style: 'aggressive',
      );

      final easyResult = await engine.computeGoalMode(
        settings: settingsWithGoal('easy-goal'),
      );
      final aggroResult = await engine.computeGoalMode(
        settings: settingsWithGoal('aggro-goal'),
      );

      // Both should have the same daily allowance because the goal target
      // is the same and it's pure cash flow math
      expect(easyResult, isNot(equals(null)));
      expect(aggroResult, isNot(equals(null)));
      expect(aggroResult!.dailyAllowance,
          closeTo(easyResult!.dailyAllowance, 0.01));
    });

    test('feasibility shows deficit when goal is unreachable', () async {
      // Goal of $100K with $0 balance = impossible
      final goalId = await createGoal(amount: 100000, daysFromNow: 30);

      final result = await engine.computeGoalMode(
        settings: settingsWithGoal(goalId),
      );

      expect(result, isNot(equals(null)));
      expect(result!.spendablePool, lessThan(0));
      expect(result.dailyAllowance, 0);
      expect(result.behindAmount, greaterThan(0));
    });

    test('feasibility passes for easily achievable goal', () async {
      final goalId = await createGoal(amount: 100, daysFromNow: 90);
      await ledger.addIncome(
        amount: 10000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );

      final result = await engine.computeGoalMode(
        settings: settingsWithGoal(goalId),
      );

      expect(result, isNot(equals(null)));
      expect(result!.spendablePool, greaterThan(0));
      expect(result.dailyAllowance, greaterThan(0));
    });

    test('recurring income included in goal mode projection', () async {
      final now = DateTime.now();
      // Goal of $2000 in 60 days
      final goalId = await createGoal(amount: 2000, daysFromNow: 60);

      // Start with $500
      await ledger.addIncome(
        amount: 500,
        date: now,
        postingType: IncomePostingType.manualOneTime,
      );

      // Recurring $500 biweekly income — should project ~4 paychecks
      await incomeRepo.insert(RecurringIncomesCompanion.insert(
        id: 'salary-1',
        name: 'Salary',
        frequency: const Value('biweekly'),
        nextPaydayDate: DateTime(now.year, now.month, now.day + 7),
        expectedAmount: const Value(500),
        isPaydayAnchor: const Value(true),
        createdAt: now,
        updatedAt: now,
      ));

      final result = await engine.computeGoalMode(
        settings: settingsWithGoal(goalId),
      );

      expect(result, isNot(equals(null)));
      // projectedIncome should include the recurring paychecks
      expect(result!.projectedIncome, greaterThanOrEqualTo(1500));
      // spendable = 500 + ~2000 income - 0 bills - 2000 goal ≈ $500+
      expect(result.spendablePool, greaterThan(0));
    });
  });
}
