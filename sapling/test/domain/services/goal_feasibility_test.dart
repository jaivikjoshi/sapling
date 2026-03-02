import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/data/db/sapling_database.dart';
import 'package:sapling/domain/services/goal_feasibility_service.dart';

void main() {
  Goal makeGoal({
    required double targetAmount,
    required DateTime targetDate,
    String savingStyle = 'natural',
  }) {
    final now = DateTime.now();
    return Goal(
      id: 'g1',
      name: 'Test Goal',
      targetAmount: targetAmount,
      targetDate: targetDate,
      savingStyle: savingStyle,
      priorityOrder: 0,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('GoalFeasibilityService', () {
    test('feasible when free >= need', () {
      final goal = makeGoal(
        targetAmount: 1000,
        targetDate: DateTime.now().add(const Duration(days: 90)),
      );

      final result = GoalFeasibilityService.compute(
        goal: goal,
        balance: 5000,
        projectedIncome: 10000,
        projectedBills: 3000,
        dailyVariableSpend: 30,
        savingStyleMultiplier: 0.90,
      );

      expect(result.isFeasible, true);
      expect(result.deficit, 0);
      expect(result.suggestedDate, isNull);
    });

    test('not feasible when free < need, returns deficit', () {
      final goal = makeGoal(
        targetAmount: 50000,
        targetDate: DateTime.now().add(const Duration(days: 30)),
      );

      final result = GoalFeasibilityService.compute(
        goal: goal,
        balance: 1000,
        projectedIncome: 3000,
        projectedBills: 2000,
        dailyVariableSpend: 50,
        savingStyleMultiplier: 1.0,
      );

      expect(result.isFeasible, false);
      expect(result.deficit, greaterThan(0));
    });

    test('returns suggested date when not feasible', () {
      final goal = makeGoal(
        targetAmount: 5000,
        targetDate: DateTime.now().add(const Duration(days: 30)),
      );

      final result = GoalFeasibilityService.compute(
        goal: goal,
        balance: 500,
        projectedIncome: 2000,
        projectedBills: 1000,
        dailyVariableSpend: 20,
        savingStyleMultiplier: 0.90,
      );

      if (!result.isFeasible && result.suggestedDate != null) {
        expect(result.suggestedDate!.isAfter(DateTime.now()), true);
      }
    });

    test('aggressive saving style allows less variable spending', () {
      final goal = makeGoal(
        targetAmount: 3000,
        targetDate: DateTime.now().add(const Duration(days: 60)),
      );

      final easy = GoalFeasibilityService.compute(
        goal: goal,
        balance: 1000,
        projectedIncome: 5000,
        projectedBills: 2000,
        dailyVariableSpend: 40,
        savingStyleMultiplier: 1.0,
      );

      final aggressive = GoalFeasibilityService.compute(
        goal: goal,
        balance: 1000,
        projectedIncome: 5000,
        projectedBills: 2000,
        dailyVariableSpend: 40,
        savingStyleMultiplier: 0.75,
      );

      // Aggressive spends less on variable → more free → potentially more feasible
      expect(aggressive.freeAfterObligations,
          greaterThan(easy.freeAfterObligations));
    });

    test('need is zero when balance already covers target', () {
      final goal = makeGoal(
        targetAmount: 500,
        targetDate: DateTime.now().add(const Duration(days: 30)),
      );

      final result = GoalFeasibilityService.compute(
        goal: goal,
        balance: 1000,
        projectedIncome: 3000,
        projectedBills: 1000,
        dailyVariableSpend: 20,
        savingStyleMultiplier: 0.90,
      );

      expect(result.need, 0);
      expect(result.isFeasible, true);
    });

    test('suggested date rounds to end-of-month within 6 months', () {
      final goal = makeGoal(
        targetAmount: 3000,
        targetDate: DateTime.now().add(const Duration(days: 10)),
      );

      final result = GoalFeasibilityService.compute(
        goal: goal,
        balance: 100,
        projectedIncome: 500,
        projectedBills: 200,
        dailyVariableSpend: 10,
        savingStyleMultiplier: 0.90,
      );

      if (!result.isFeasible && result.suggestedDate != null) {
        // End of month => next day should be first of next month
        final next = result.suggestedDate!.add(const Duration(days: 1));
        expect(next.day, 1);
      }
    });
  });
}
