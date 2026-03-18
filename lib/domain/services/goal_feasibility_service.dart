import '../../data/db/leko_database.dart';

class GoalFeasibilityResult {
  final bool isFeasible;
  final double deficit;
  final DateTime? suggestedDate;
  final double freeAfterObligations;
  final double need;

  const GoalFeasibilityResult({
    required this.isFeasible,
    required this.deficit,
    this.suggestedDate,
    required this.freeAfterObligations,
    required this.need,
  });
}

abstract final class GoalFeasibilityService {
  /// Check if a goal is feasible given the current financial state.
  /// PRD 5.9: Free = Bal + I_h - B_h - (AllowedVarPerDay * H)
  ///          Feasible if Free >= Need
  static GoalFeasibilityResult compute({
    required Goal goal,
    required double balance,
    required double projectedIncome,
    required double projectedBills,
    required double dailyVariableSpend,
    required double savingStyleMultiplier,
  }) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(
        goal.targetDate.year, goal.targetDate.month, goal.targetDate.day);
    final horizon = targetDay.difference(todayStart).inDays + 1;
    final h = horizon < 1 ? 1 : horizon;

    final allowedVarPerDay = savingStyleMultiplier * dailyVariableSpend;
    final free =
        balance + projectedIncome - projectedBills - (allowedVarPerDay * h);
    final need = goal.targetAmount - balance;
    final actualNeed = need > 0 ? need : 0.0;
    final feasible = free >= actualNeed;
    final deficit = feasible ? 0.0 : actualNeed - free;

    DateTime? suggested;
    if (!feasible) {
      suggested = _suggestDate(
        balance: balance,
        need: actualNeed,
        dailyFree: _dailyFree(
          projectedIncome: projectedIncome,
          projectedBills: projectedBills,
          allowedVarPerDay: allowedVarPerDay,
          horizon: h,
        ),
        todayStart: todayStart,
      );
    }

    return GoalFeasibilityResult(
      isFeasible: feasible,
      deficit: deficit,
      suggestedDate: suggested,
      freeAfterObligations: free,
      need: actualNeed,
    );
  }

  static double _dailyFree({
    required double projectedIncome,
    required double projectedBills,
    required double allowedVarPerDay,
    required int horizon,
  }) {
    final totalFree = projectedIncome - projectedBills - (allowedVarPerDay * horizon);
    return totalFree / horizon;
  }

  /// PRD 5.10: simulate forward day-by-day; round to end-of-month
  /// (within 6 months) or end-of-quarter (> 6 months).
  static DateTime? _suggestDate({
    required double balance,
    required double need,
    required double dailyFree,
    required DateTime todayStart,
  }) {
    if (dailyFree <= 0) return null;

    var cumulative = balance;
    var day = todayStart;
    for (var i = 0; i < 3650; i++) {
      cumulative += dailyFree;
      day = DateTime(day.year, day.month, day.day + 1);
      if (cumulative >= need) {
        return _roundDate(day, todayStart);
      }
    }
    return null;
  }

  static DateTime _roundDate(DateTime raw, DateTime today) {
    final monthsDiff =
        (raw.year - today.year) * 12 + (raw.month - today.month);

    if (monthsDiff <= 6) {
      // Round up to end-of-month
      final endOfMonth = DateTime(raw.year, raw.month + 1, 0);
      return endOfMonth;
    } else {
      // Round up to end-of-quarter
      final quarterEnd = ((raw.month - 1) ~/ 3 + 1) * 3;
      return DateTime(raw.year, quarterEnd + 1, 0);
    }
  }
}
