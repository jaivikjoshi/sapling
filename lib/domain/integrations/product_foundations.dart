class BadgeProgressSnapshot {
  const BadgeProgressSnapshot({
    required this.expenseCount,
    required this.goalCount,
    required this.trackingStreakDays,
    required this.underBudgetToday,
    required this.savedThisWeek,
    required this.billPaidOnTime,
  });

  final int expenseCount;
  final int goalCount;
  final int trackingStreakDays;
  final bool underBudgetToday;
  final bool savedThisWeek;
  final bool billPaidOnTime;
}

enum LocalBadgeId {
  firstExpenseAdded,
  firstGoalCreated,
  sevenDayTrackingStreak,
  underBudgetToday,
  savedThisWeek,
  billPaidOnTime,
}

class LocalBadgeEngine {
  const LocalBadgeEngine();

  Set<LocalBadgeId> earned(BadgeProgressSnapshot snapshot) {
    return {
      if (snapshot.expenseCount > 0) LocalBadgeId.firstExpenseAdded,
      if (snapshot.goalCount > 0) LocalBadgeId.firstGoalCreated,
      if (snapshot.trackingStreakDays >= 7) LocalBadgeId.sevenDayTrackingStreak,
      if (snapshot.underBudgetToday) LocalBadgeId.underBudgetToday,
      if (snapshot.savedThisWeek) LocalBadgeId.savedThisWeek,
      if (snapshot.billPaidOnTime) LocalBadgeId.billPaidOnTime,
    };
  }
}

class SavingsContributionPoint {
  const SavingsContributionPoint({required this.date, required this.amount});

  final DateTime date;
  final double amount;
}

class SavingsGrowthPoint {
  const SavingsGrowthPoint({
    required this.date,
    required this.balance,
    required this.progress,
  });

  final DateTime date;
  final double balance;
  final double progress;
}

class SavingsGrowthSeriesBuilder {
  const SavingsGrowthSeriesBuilder();

  List<SavingsGrowthPoint> build({
    required double targetAmount,
    required List<SavingsContributionPoint> contributions,
  }) {
    final sorted = [...contributions]..sort((a, b) => a.date.compareTo(b.date));
    var running = 0.0;
    return [
      for (final contribution in sorted)
        SavingsGrowthPoint(
          date: contribution.date,
          balance: running += contribution.amount,
          progress:
              targetAmount <= 0 ? 0 : (running / targetAmount).clamp(0.0, 1.0),
        ),
    ];
  }
}

enum HouseholdRole { owner, partner, viewer }

class HouseholdMemberDraft {
  const HouseholdMemberDraft({required this.displayName, required this.role});

  final String displayName;
  final HouseholdRole role;
}

enum DynamicReportType {
  recurringSubscriptionDrift,
  billVariance,
  categoryAnomaly,
  weeklyForecast,
  monthlyForecast,
}

class DynamicReportRequest {
  const DynamicReportRequest({
    required this.type,
    required this.periodStart,
    required this.periodEnd,
  });

  final DynamicReportType type;
  final DateTime periodStart;
  final DateTime periodEnd;
}
