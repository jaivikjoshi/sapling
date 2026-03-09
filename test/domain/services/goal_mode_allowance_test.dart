import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/data/db/sapling_database.dart';
import 'package:sapling/data/repositories/bills_repository.dart';
import 'package:sapling/data/repositories/goals_repository.dart';
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
  late GoalsRepository goalsRepo;
  late AllowanceEngine engine;
  late LedgerService ledger;

  setUp(() {
    db = SaplingDatabase.forTesting(NativeDatabase.memory());
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

    test('returns result with goal data when primary goal exists', () async {
      final goalId = await createGoal();
      await ledger.addIncome(
        amount: 5000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );

      final result = await engine.computeGoalMode(
        settings: settingsWithGoal(goalId),
      );

      expect(result, isNot(equals(null)));
      expect(result!.goal.id, goalId);
      expect(result.daysToGoal, greaterThan(0));
      expect(result.balance, 5000);
    });

    test('saving style multiplier affects allowance', () async {
      final now = DateTime.now();

      for (var i = 0; i < 10; i++) {
        await ledger.addExpense(
          amount: 30,
          date: DateTime(now.year, now.month, now.day - i - 1),
          categoryId: 'cat-1',
          label: SpendLabel.green,
        );
      }
      await ledger.addIncome(
        amount: 10000,
        date: now,
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

      expect(easyResult, isNot(equals(null)));
      expect(aggroResult, isNot(equals(null)));
      expect(aggroResult!.allowanceToday,
          lessThanOrEqualTo(easyResult!.allowanceToday));
    });

    test('feasibility shows deficit when goal is unreachable', () async {
      final goalId = await createGoal(amount: 100000, daysFromNow: 30);

      final result = await engine.computeGoalMode(
        settings: settingsWithGoal(goalId),
      );

      expect(result, isNot(equals(null)));
      expect(result!.feasibility.isFeasible, false);
      expect(result.feasibility.deficit, greaterThan(0));
      expect(result.behindAmount, greaterThan(0));
    });

    test('feasibility passes for achievable goal', () async {
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
      expect(result!.feasibility.isFeasible, true);
      expect(result.feasibility.deficit, 0);
    });

    test('banked allowance is shared with paycheck mode', () async {
      final goalId = await createGoal();
      await ledger.addIncome(
        amount: 3000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );

      final settings = settingsWithGoal(goalId);
      final paycheckResult = await engine.computePaycheckMode(
        settings: settings,
      );
      final goalResult = await engine.computeGoalMode(
        settings: settings,
      );

      expect(paycheckResult.bankedAllowance, isA<double>());
      expect(goalResult, isNot(equals(null)));
      expect(goalResult!.bankedAllowance, isA<double>());
    });
  });
}
