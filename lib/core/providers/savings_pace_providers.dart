import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/leko_database.dart';
import 'goals_providers.dart';
import 'ledger_providers.dart';
import 'settings_providers.dart';

/// Status of a goal's savings pace relative to a linear target line.
enum SavingsStatus { onTrack, ahead, behind }

/// A single point in the saved-toward-goal time series.
class SavingsPoint {
  const SavingsPoint({required this.date, required this.amount});

  final DateTime date;
  final double amount;
}

/// Aggregate data used by [SavingsPaceCard] to render Wealthsimple-style
/// "Savings Pace" hero.
class SavingsPaceData {
  const SavingsPaceData({
    required this.goalId,
    required this.goalName,
    required this.savedAmount,
    required this.targetAmount,
    required this.startDate,
    required this.targetDate,
    required this.history,
    required this.status,
    required this.insight,
  });

  final String goalId;
  final String goalName;
  final double savedAmount;
  final double targetAmount;
  final DateTime startDate;
  final DateTime targetDate;
  final List<SavingsPoint> history;
  final SavingsStatus status;
  final String insight;

  double get progress =>
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0.0, 1.0);
}

/// Resolves the primary goal: explicit `primaryGoalId` first, otherwise the
/// first goal by priority (matches existing convention on home screen).
final _primaryGoalProvider = Provider<Goal?>((ref) {
  final goals = ref.watch(goalsStreamProvider).valueOrNull ?? const <Goal>[];
  if (goals.isEmpty) return null;
  final settings = ref.watch(settingsStreamProvider).valueOrNull;
  if (settings?.primaryGoalId != null) {
    for (final goal in goals) {
      if (goal.id == settings!.primaryGoalId) return goal;
    }
  }
  return goals.first;
});

/// Builds the savings-pace snapshot for the active primary goal. Returns
/// `null` when there is no eligible goal.
final savingsPaceProvider = FutureProvider<SavingsPaceData?>((ref) async {
  final goal = ref.watch(_primaryGoalProvider);
  if (goal == null) return null;
  if (goal.targetAmount <= 0) return null;

  // Re-run whenever the ledger mutates so the history line stays live.
  ref.watch(balanceStreamProvider);

  final txnRepo = ref.read(transactionsRepositoryProvider);
  final allTxns = await txnRepo.getAll();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final created = goal.createdAt;
  final startDate = DateTime(created.year, created.month, created.day);
  final targetDate = DateTime(
    goal.targetDate.year,
    goal.targetDate.month,
    goal.targetDate.day,
  );

  // Build a per-day saved-toward-goal series from the goal's createdAt
  // through today (capped at target amount). For long horizons we down-sample
  // to keep the chart tidy.
  final history = _buildSavingsHistory(
    transactions: allTxns,
    startDate: startDate,
    today: today,
    targetAmount: goal.targetAmount,
  );

  final saved = history.isEmpty ? 0.0 : history.last.amount;

  // Linear ideal pace from 0 → targetAmount across [startDate, targetDate].
  final totalSpan = math.max(targetDate.difference(startDate).inDays, 1);
  final elapsed = today.difference(startDate).inDays.clamp(0, totalSpan);
  final idealToday = goal.targetAmount * (elapsed / totalSpan);

  final gap = saved - idealToday;
  final status = _statusForGap(gap: gap, target: goal.targetAmount);
  final insight = _insightFor(
    status: status,
    saved: saved,
    target: goal.targetAmount,
    today: today,
    targetDate: targetDate,
    gap: gap,
  );

  return SavingsPaceData(
    goalId: goal.id,
    goalName: goal.name,
    savedAmount: saved,
    targetAmount: goal.targetAmount,
    startDate: startDate,
    targetDate: targetDate,
    history: history,
    status: status,
    insight: insight,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Helpers

List<SavingsPoint> _buildSavingsHistory({
  required List<Transaction> transactions,
  required DateTime startDate,
  required DateTime today,
  required double targetAmount,
}) {
  // Running balance up to and including a given day, applied across all
  // transactions (matches GoalsService convention of treating total balance
  // as savings toward the goal, capped at the target).
  final sorted = [...transactions]..sort((a, b) => a.date.compareTo(b.date));

  // Walk all transactions once and compute the cumulative balance at the
  // end of each day.
  final dailyDelta = <DateTime, double>{};
  for (final txn in sorted) {
    final day = DateTime(txn.date.year, txn.date.month, txn.date.day);
    final delta = switch (txn.type) {
      'income' => txn.amount,
      'expense' => -txn.amount,
      'adjustment' => txn.amount,
      _ => 0.0,
    };
    dailyDelta[day] = (dailyDelta[day] ?? 0) + delta;
  }

  // Balance up to (and including) startDate inclusive is the baseline.
  double balance = 0;
  for (final entry in dailyDelta.entries) {
    if (!entry.key.isAfter(startDate)) balance += entry.value;
  }

  final span = today.difference(startDate).inDays;
  if (span < 0) {
    // Goal was created in the future — degenerate case; show a single point.
    return [
      SavingsPoint(date: startDate, amount: _clampSaved(balance, targetAmount)),
    ];
  }

  // Pick a sampling stride so the chart never carries more than ~60 points.
  final stride = span <= 60 ? 1 : (span / 60).ceil();
  final points = <SavingsPoint>[];
  for (var dayOffset = 0; dayOffset <= span; dayOffset += stride) {
    final cursor = DateTime(
      startDate.year,
      startDate.month,
      startDate.day + dayOffset,
    );
    if (dayOffset > 0) {
      // Advance the balance through every day we just skipped.
      for (var i = dayOffset - stride + 1; i <= dayOffset; i++) {
        final day = DateTime(
          startDate.year,
          startDate.month,
          startDate.day + i,
        );
        balance += dailyDelta[day] ?? 0;
      }
    }
    final amount = _clampSaved(balance, targetAmount);
    points.add(SavingsPoint(date: cursor, amount: amount));
  }

  // Always anchor the final point at "today" with the latest balance so the
  // chart's right edge matches the headline number, even after down-sampling.
  if (points.isEmpty || points.last.date != today) {
    // Advance through any remaining days the loop skipped.
    final lastDate = points.isEmpty ? startDate : points.last.date;
    final remaining = today.difference(lastDate).inDays;
    for (var i = 1; i <= remaining; i++) {
      final day = DateTime(lastDate.year, lastDate.month, lastDate.day + i);
      balance += dailyDelta[day] ?? 0;
    }
    final amount = _clampSaved(balance, targetAmount);
    points.add(SavingsPoint(date: today, amount: amount));
  }

  return points;
}

double _clampSaved(double balance, double target) {
  if (balance <= 0) return 0;
  if (balance >= target) return target;
  return balance;
}

SavingsStatus _statusForGap({required double gap, required double target}) {
  // Use 3% of the target as the "on track" tolerance band so a tiny
  // numerical drift doesn't flip the label every day.
  final tolerance = math.max(target * 0.03, 5.0);
  if (gap > tolerance) return SavingsStatus.ahead;
  if (gap < -tolerance) return SavingsStatus.behind;
  return SavingsStatus.onTrack;
}

String _insightFor({
  required SavingsStatus status,
  required double saved,
  required double target,
  required DateTime today,
  required DateTime targetDate,
  required double gap,
}) {
  final daysLeft = math.max(targetDate.difference(today).inDays, 1);
  final remaining = math.max(target - saved, 0);
  final dailyNeeded = remaining / daysLeft;

  String fmt(double v) {
    final rounded = v.round();
    return '\$$rounded';
  }

  switch (status) {
    case SavingsStatus.ahead:
      // Soft "this week" framing — gap is overall lead but reads naturally.
      return 'Ahead by ${fmt(gap.abs())} this week';
    case SavingsStatus.behind:
      // Weekly catch-up amount — pace the deficit across the remaining days.
      final catchupWeek = (gap.abs() / math.max(daysLeft, 7)) * 7;
      return 'Add ${fmt(catchupWeek)} this week to catch up';
    case SavingsStatus.onTrack:
      if (remaining <= 0) return 'Goal funded — keep going';
      return 'Save ${fmt(dailyNeeded)}/day to stay on track';
  }
}
