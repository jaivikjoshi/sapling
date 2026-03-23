import '../../data/db/leko_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/services/allowance_engine.dart';

/// Snapshot of app data used by Leaf UI and deterministic responses.
class LeafContext {
  const LeafContext({
    required this.greetingName,
    required this.allowanceMode,
    this.settings,
    this.balance,
    this.paycheck,
    this.goal,
    this.primaryGoal,
    this.upcomingBills = const [],
    this.recentTransactions = const [],
  });

  final String greetingName;
  final AllowanceMode allowanceMode;
  final UserSettings? settings;
  final double? balance;
  final PaycheckAllowanceResult? paycheck;
  final GoalAllowanceResult? goal;
  final Goal? primaryGoal;
  final List<Bill> upcomingBills;
  final List<Transaction> recentTransactions;

  /// Active allowance numbers for the current mode, when available.
  double? get dailyAllowance {
    return switch (allowanceMode) {
      AllowanceMode.paycheck => paycheck?.dailyAllowance,
      AllowanceMode.goal => goal?.dailyAllowance,
    };
  }

  double? get remainingToday {
    return switch (allowanceMode) {
      AllowanceMode.paycheck => paycheck?.remainingToday,
      AllowanceMode.goal => goal?.remainingToday,
    };
  }

  double? get todaySpend {
    return switch (allowanceMode) {
      AllowanceMode.paycheck => paycheck?.todaySpend,
      AllowanceMode.goal => goal?.todaySpend,
    };
  }

  Bill? get nextBill {
    if (upcomingBills.isEmpty) return null;
    final sorted = [...upcomingBills]
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return sorted.first;
  }
}

enum LeafQueryKind {
  spendingToday,
  bills,
  goal,
  thisCycle,
}
