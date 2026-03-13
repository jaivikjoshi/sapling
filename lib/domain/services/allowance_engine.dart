import '../../core/utils/enum_serialization.dart';
import '../../data/db/sapling_database.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/goals_repository.dart';
import '../../data/repositories/recurring_income_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../models/enums.dart';
import '../models/settings_model.dart';
import 'cycle_window_calculator.dart';
import 'goal_feasibility_service.dart';
import 'projection_service.dart';

// ── Result types ──

class PaycheckAllowanceResult {
  final double balance;

  /// The daily spending budget for this cycle.
  final double dailyAllowance;

  /// How much the user has already spent today.
  final double todaySpend;

  /// How much the user can still spend today: dailyAllowance - todaySpend.
  final double remainingToday;

  /// How far behind the user is (positive = overspent overall).
  final double behindAmount;

  final double projectedIncome;
  final double projectedBills;
  final double spendablePool;
  final int daysLeft;
  final CycleWindow cycleWindow;

  const PaycheckAllowanceResult({
    required this.balance,
    required this.dailyAllowance,
    required this.todaySpend,
    required this.remainingToday,
    required this.behindAmount,
    required this.projectedIncome,
    required this.projectedBills,
    required this.spendablePool,
    required this.daysLeft,
    required this.cycleWindow,
  });

  // Keep backward compatibility for UI code reading allowanceToday
  double get allowanceToday => dailyAllowance;
  double get bankedAllowance => 0;
}

class GoalAllowanceResult {
  final double balance;

  /// The daily spending budget that lets you reach your goal on time.
  final double dailyAllowance;

  /// How much the user has already spent today.
  final double todaySpend;

  /// How much the user can still spend today: dailyAllowance - todaySpend.
  final double remainingToday;

  /// How far behind the user is (positive = goal is unreachable at current pace).
  final double behindAmount;

  final double projectedIncome;
  final double projectedBills;
  final double spendablePool;
  final int daysToGoal;
  final Goal goal;
  final GoalFeasibilityResult feasibility;
  final CycleWindow cycleWindow;

  const GoalAllowanceResult({
    required this.balance,
    required this.dailyAllowance,
    required this.todaySpend,
    required this.remainingToday,
    required this.behindAmount,
    required this.projectedIncome,
    required this.projectedBills,
    required this.spendablePool,
    required this.daysToGoal,
    required this.goal,
    required this.feasibility,
    required this.cycleWindow,
  });

  // Keep backward compatibility for UI code reading allowanceToday
  double get allowanceToday => dailyAllowance;
  double get bankedAllowance => 0;
}

/// Used by CloseoutService for budget-based streak; allows tests to inject a fake.
abstract class AllowanceEngineForStreak {
  Future<bool> wasWithinBudgetOnDate(DateTime date, UserSettings settings);
}

class AllowanceEngine implements AllowanceEngineForStreak {
  final TransactionsRepository _txnRepo;
  final BillsRepository _billsRepo;
  final RecurringIncomeRepository _incomeRepo;
  final GoalsRepository? _goalsRepo;

  AllowanceEngine(
    this._txnRepo,
    this._billsRepo,
    this._incomeRepo, [
    this._goalsRepo,
  ]);

  // ══════════════════════════════════════════════════════════════════════
  // PAYCHECK MODE
  //
  // "How much can I spend per day to make this paycheck last until the
  //  next one?"
  //
  // Formula:
  //   spendablePool = balance + projectedIncome - projectedBills
  //   dailyAllowance = spendablePool / daysLeft
  //   remainingToday = dailyAllowance - todaySpend
  //
  // Overspend carry-forward is automatic: yesterday's overspend lowered
  // the balance, so today's recalculation naturally distributes the
  // impact across remaining days.
  // ══════════════════════════════════════════════════════════════════════

  Future<PaycheckAllowanceResult> computePaycheckMode({
    required UserSettings settings,
  }) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Determine cycle boundaries
    final anchor = await _incomeRepo.getAnchor();
    final cycle = CycleWindowCalculator.compute(
      resetType: settings.rolloverResetType,
      now: now,
      anchorFrequency: anchor?.frequency,
      anchorNextPaydayDate: anchor?.nextPaydayDate,
    );

    // Current balance (all posted transactions)
    final balance = await _txnRepo.computeBalance();

    // Transactions within this cycle (for today-spend calc)
    final allTxns = await _txnRepo.getByDateRange(cycle.start, cycle.end);
    final incomeTxns = allTxns.where((t) => t.type == 'income').toList();
    final billPaidTxns =
        allTxns.where((t) => t.linkedBillId != null).toList();

    final schedules = await _incomeRepo.getAll();
    final bills = await _billsRepo.getAll();

    // Project income & bills to cycle end.
    // ProjectionService includes confirmed transactions in its total,
    // but those are already reflected in `balance`. Subtract confirmed
    // amounts so we only count truly future income/bills.
    final grossProjectedIncome = ProjectionService.projectIncome(
      start: todayStart, end: cycle.end,
      confirmedIncome: incomeTxns, schedules: schedules,
    );
    final confirmedIncomeInWindow = incomeTxns
        .where((t) => !t.date.isBefore(todayStart) && t.date.isBefore(cycle.end))
        .fold<double>(0, (sum, t) => sum + t.amount);
    final futureIncome = grossProjectedIncome - confirmedIncomeInWindow;

    final grossProjectedBills = ProjectionService.projectBills(
      start: todayStart, end: cycle.end,
      bills: bills, paidBillTransactions: billPaidTxns,
    );
    // Bills that are already paid are excluded by ProjectionService,
    // so grossProjectedBills = future-only bills already. No dedup needed.
    final futureBills = grossProjectedBills;

    // ── Core formula ──
    final daysLeft = cycle.daysLeft;
    final spendablePool = balance + futureIncome - futureBills;
    final dailyAllowance = spendablePool > 0
        ? spendablePool / daysLeft
        : 0.0;

    // ── Today's spend ──
    final todaySpend = _computeTodaySpend(allTxns, todayStart);
    final remainingToday = dailyAllowance - todaySpend;

    // ── Behind amount ──
    final behindAmount = spendablePool < 0
        ? spendablePool.abs()
        : 0.0;

    return PaycheckAllowanceResult(
      balance: balance,
      dailyAllowance: dailyAllowance,
      todaySpend: todaySpend,
      remainingToday: remainingToday,
      behindAmount: behindAmount,
      projectedIncome: futureIncome,
      projectedBills: futureBills,
      spendablePool: spendablePool,
      daysLeft: daysLeft,
      cycleWindow: cycle,
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // GOAL MODE
  //
  // "How much can I spend per day and still have $X saved by [date]?"
  //
  // Formula:
  //   spendablePool = balance + projectedIncome - projectedBills - goalTarget
  //   dailyAllowance = spendablePool / daysToGoal
  //   remainingToday = dailyAllowance - todaySpend
  //
  // Example: Balance=$1000, income to goal=$4000, bills=$1500, goal=$2000
  //   spendable = 1000 + 4000 - 1500 - 2000 = $1500
  //   If 60 days to goal → dailyAllowance = $25/day
  //
  // If you overspend by $5 today, tomorrow your balance is $5 lower,
  // so the recalculation naturally tightens the remaining days.
  // ══════════════════════════════════════════════════════════════════════

  Future<GoalAllowanceResult?> computeGoalMode({
    required UserSettings settings,
  }) async {
    if (settings.primaryGoalId == null || _goalsRepo == null) return null;

    final goal = await _goalsRepo.getById(settings.primaryGoalId!);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(
        goal.targetDate.year, goal.targetDate.month, goal.targetDate.day);
    final horizon = targetDay.difference(todayStart).inDays + 1;
    final daysToGoal = horizon < 1 ? 1 : horizon;
    final horizonEnd = DateTime(
        todayStart.year, todayStart.month, todayStart.day + daysToGoal);

    // Cycle (for UI display)
    final anchor = await _incomeRepo.getAnchor();
    final cycle = CycleWindowCalculator.compute(
      resetType: settings.rolloverResetType, now: now,
      anchorFrequency: anchor?.frequency,
      anchorNextPaydayDate: anchor?.nextPaydayDate,
    );

    // Current balance
    final balance = await _txnRepo.computeBalance();

    // Transactions (for today-spend calc)
    final allTxns = await _txnRepo.getByDateRange(cycle.start, cycle.end);
    final incomeTxns = allTxns.where((t) => t.type == 'income').toList();
    final billPaidTxns =
        allTxns.where((t) => t.linkedBillId != null).toList();

    final schedules = await _incomeRepo.getAll();
    final bills = await _billsRepo.getAll();

    // Project income & bills to goal date.
    // Subtract confirmed income that's already in balance.
    final grossProjectedIncome = ProjectionService.projectIncome(
      start: todayStart, end: horizonEnd,
      confirmedIncome: incomeTxns, schedules: schedules,
    );
    final confirmedIncomeInWindow = incomeTxns
        .where((t) => !t.date.isBefore(todayStart) && t.date.isBefore(horizonEnd))
        .fold<double>(0, (sum, t) => sum + t.amount);
    final futureIncome = grossProjectedIncome - confirmedIncomeInWindow;

    final futureBills = ProjectionService.projectBills(
      start: todayStart, end: horizonEnd,
      bills: bills, paidBillTransactions: billPaidTxns,
    );

    // ── Core formula ──
    // Everything coming in, minus everything going out, minus what you
    // need to have saved = what you can freely spend over the whole horizon
    final goalTarget = goal.targetAmount;
    final spendablePool =
        balance + futureIncome - futureBills - goalTarget;
    final dailyAllowance = spendablePool > 0
        ? spendablePool / daysToGoal
        : 0.0;

    // ── Today's spend ──
    final todaySpend = _computeTodaySpend(allTxns, todayStart);
    final remainingToday = dailyAllowance - todaySpend;

    // ── Feasibility check ──
    final baselineDailySpend = _computeBaselineDailySpend(
      allTxns: await _txnRepo.getAll(),
      windowDays: settings.spendingBaselineDays,
    );
    final style = enumFromDb<SavingStyle>(
        goal.savingStyle, SavingStyle.values);
    final feasibility = GoalFeasibilityService.compute(
      goal: goal, balance: balance,
      projectedIncome: futureIncome, projectedBills: futureBills,
      dailyVariableSpend: baselineDailySpend,
      savingStyleMultiplier: style.multiplier,
    );

    final behindAmount = spendablePool < 0
        ? spendablePool.abs()
        : (!feasibility.isFeasible ? feasibility.deficit : 0.0);

    return GoalAllowanceResult(
      balance: balance,
      dailyAllowance: dailyAllowance,
      todaySpend: todaySpend,
      remainingToday: remainingToday,
      behindAmount: behindAmount,
      projectedIncome: futureIncome,
      projectedBills: futureBills,
      spendablePool: spendablePool,
      daysToGoal: daysToGoal,
      goal: goal,
      feasibility: feasibility,
      cycleWindow: cycle,
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════════════

  /// Sum all expenses posted today.
  double _computeTodaySpend(List<Transaction> txns, DateTime todayStart) {
    double total = 0;
    for (final txn in txns) {
      final txnDay = DateTime(txn.date.year, txn.date.month, txn.date.day);
      if (txnDay == todayStart && txn.type == 'expense') {
        total += txn.amount;
      }
    }
    return total;
  }

  /// PRD 5.6: Variable spending baseline = non-bill expenses / W days
  double _computeBaselineDailySpend({
    required List<Transaction> allTxns,
    required int windowDays,
  }) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day - windowDays);
    double varSum = 0;
    for (final txn in allTxns) {
      if (txn.type == 'expense' &&
          txn.linkedBillId == null &&
          !txn.date.isBefore(cutoff)) {
        varSum += txn.amount;
      }
    }
    return windowDays > 0 ? varSum / windowDays : 0;
  }

  Future<double> computeBehindAmount({
    required UserSettings settings,
  }) async {
    final result = await computePaycheckMode(settings: settings);
    return result.behindAmount;
  }

  /// Whether spending on [date] was within that day's budget (for streak).
  /// Simple check: was total spend on that day ≤ the daily allowance
  /// that would have been calculated for that day's cycle?
  @override
  Future<bool> wasWithinBudgetOnDate(
    DateTime date,
    UserSettings settings,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final monthStart = DateTime(date.year, date.month, 1);
    final monthEnd = date.month == 12
        ? DateTime(date.year + 1, 1, 1)
        : DateTime(date.year, date.month + 1, 1);

    final balanceAtMonthStart =
        await _txnRepo.computeBalanceUpTo(monthStart);
    final allTxns = await _txnRepo.getByDateRange(monthStart, monthEnd);
    final incomeTxns = allTxns.where((t) => t.type == 'income').toList();
    final billPaidTxns =
        allTxns.where((t) => t.linkedBillId != null).toList();

    final schedules = await _incomeRepo.getAll();
    final bills = await _billsRepo.getAll();

    final projectedIncome = ProjectionService.projectIncome(
      start: monthStart,
      end: monthEnd,
      confirmedIncome: incomeTxns,
      schedules: schedules,
    );
    final projectedBills = ProjectionService.projectBills(
      start: monthStart,
      end: monthEnd,
      bills: bills,
      paidBillTransactions: billPaidTxns,
    );

    final available = balanceAtMonthStart + projectedIncome - projectedBills;
    final daysInMonth = monthEnd.difference(monthStart).inDays;
    final dailyBase = daysInMonth > 0 && available > 0
        ? available / daysInMonth
        : 0.0;

    double spendOnDay = 0;
    for (final t in allTxns) {
      final tDay = DateTime(t.date.year, t.date.month, t.date.day);
      if (tDay == dayStart && t.type == 'expense') spendOnDay += t.amount;
    }

    return spendOnDay <= dailyBase;
  }
}
