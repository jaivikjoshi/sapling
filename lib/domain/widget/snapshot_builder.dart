import '../models/daily_snapshot.dart';
import '../services/allowance_engine.dart';
import '../services/closeout_service.dart';

/// Builds a DailySnapshot from current allowance, streak, and optional goal.
/// Tree stage is derived from streak (no heavy logic; widget renders offline).
class SnapshotBuilder {
  /// Tree stage from budget streak. Pure function for testing.
  static String treeStageFromStreak(int currentStreak) {
    if (currentStreak >= 7) return 'tree';
    if (currentStreak >= 1) return 'leko';
    return 'seedling';
  }

  /// Format closeout status for widget: "3 day streak · Within budget" or "Over budget".
  static String formatCloseoutStatus(int streak, bool todayWithinBudget) {
    if (streak > 0) {
      final day = streak == 1 ? 'day' : 'days';
      final today = todayWithinBudget ? 'Within budget' : 'Over budget';
      return '$streak $day streak · $today';
    }
    return todayWithinBudget ? 'Within budget' : 'Over budget';
  }

  /// Build snapshot from paycheck-mode result and streak. Use when no primary goal.
  static DailySnapshot fromPaycheck(
    PaycheckAllowanceResult allowance,
    StreakResult streak,
  ) {
    return DailySnapshot(
      todayAllowance: allowance.allowanceToday,
      behindAmount: allowance.behindAmount,
      primaryGoalProgress: null,
      treeStage: treeStageFromStreak(streak.currentStreak),
      closeoutStatus: formatCloseoutStatus(
        streak.currentStreak,
        streak.todayWithinBudget,
      ),
      timestamp: DateTime.now(),
    );
  }

  /// Build snapshot from goal-mode result and streak.
  static DailySnapshot fromGoal(
    GoalAllowanceResult allowance,
    StreakResult streak,
  ) {
    final goal = allowance.goal;
    final progress = goal.targetAmount > 0
        ? (allowance.balance / goal.targetAmount).clamp(0.0, 1.0)
        : null;
    return DailySnapshot(
      todayAllowance: allowance.allowanceToday,
      behindAmount: allowance.behindAmount,
      primaryGoalProgress: progress,
      treeStage: treeStageFromStreak(streak.currentStreak),
      closeoutStatus: formatCloseoutStatus(
        streak.currentStreak,
        streak.todayWithinBudget,
      ),
      timestamp: DateTime.now(),
    );
  }
}
