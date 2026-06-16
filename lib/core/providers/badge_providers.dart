import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/leko_database.dart';
import '../../domain/integrations/product_foundations.dart';
import '../../domain/models/enums.dart';
import 'allowance_providers.dart';
import 'goals_providers.dart';
import 'integration_providers.dart';
import 'ledger_providers.dart';

final badgeProgressSnapshotProvider = Provider<BadgeProgressSnapshot>((ref) {
  final transactions =
      ref.watch(recentTransactionsProvider).valueOrNull ?? const [];
  final goals = ref.watch(goalsStreamProvider).valueOrNull ?? const [];
  final mode = ref.watch(effectiveAllowanceModeProvider);
  final paycheck = ref.watch(paycheckAllowanceProvider).valueOrNull;
  final goal = ref.watch(goalAllowanceProvider).valueOrNull;
  final remainingToday = switch (mode) {
    AllowanceMode.paycheck => paycheck?.remainingToday,
    AllowanceMode.goal => goal?.remainingToday,
  };

  final expenseCount =
      transactions.where((txn) => txn.type == 'expense').length;
  final trackingStreak = _trackingStreakDays(transactions);
  final underBudgetToday = remainingToday != null && remainingToday >= 0;
  final savedThisWeek = _netThisWeek(transactions) > 0;
  final billPaidOnTime = transactions.any(
    (txn) => txn.type == 'expense' && txn.linkedBillId != null,
  );

  return BadgeProgressSnapshot(
    expenseCount: expenseCount,
    goalCount: goals.length,
    trackingStreakDays: trackingStreak,
    underBudgetToday: underBudgetToday,
    savedThisWeek: savedThisWeek,
    billPaidOnTime: billPaidOnTime,
  );
});

final earnedBadgesProvider = Provider<Set<LocalBadgeId>>((ref) {
  return ref
      .watch(localBadgeEngineProvider)
      .earned(ref.watch(badgeProgressSnapshotProvider));
});

int _trackingStreakDays(List<Transaction> transactions) {
  final activeDays = <String>{};
  for (final txn in transactions) {
    activeDays.add(_dayKey(txn.date));
  }
  var streak = 0;
  var cursor = DateTime.now();
  while (activeDays.contains(_dayKey(cursor))) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

double _netThisWeek(List<Transaction> transactions) {
  final now = DateTime.now();
  final weekStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  var income = 0.0;
  var expenses = 0.0;
  for (final txn in transactions) {
    if (txn.date.isBefore(weekStart)) continue;
    if (txn.type == 'income') income += txn.amount;
    if (txn.type == 'expense') expenses += txn.amount;
  }
  return income - expenses;
}

String _dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';
