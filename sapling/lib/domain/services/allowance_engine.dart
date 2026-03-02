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

class PaycheckAllowanceResult {
  final double balance;
  final double allowanceToday;
  final double bankedAllowance;
  final double behindAmount;
  final double projectedIncome;
  final double projectedBills;
  final int daysLeft;
  final CycleWindow cycleWindow;

  const PaycheckAllowanceResult({
    required this.balance,
    required this.allowanceToday,
    required this.bankedAllowance,
    required this.behindAmount,
    required this.projectedIncome,
    required this.projectedBills,
    required this.daysLeft,
    required this.cycleWindow,
  });
}

class GoalAllowanceResult {
  final double balance;
  final double allowanceToday;
  final double bankedAllowance;
  final double behindAmount;
  final double projectedIncome;
  final double projectedBills;
  final int daysToGoal;
  final Goal goal;
  final GoalFeasibilityResult feasibility;
  final CycleWindow cycleWindow;

  const GoalAllowanceResult({
    required this.balance,
    required this.allowanceToday,
    required this.bankedAllowance,
    required this.behindAmount,
    required this.projectedIncome,
    required this.projectedBills,
    required this.daysToGoal,
    required this.goal,
    required this.feasibility,
    required this.cycleWindow,
  });
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

  // ── Paycheck mode (PRD 5.8) ──

  Future<PaycheckAllowanceResult> computePaycheckMode({
    required UserSettings settings,
  }) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final anchor = await _incomeRepo.getAnchor();
    final cycle = CycleWindowCalculator.compute(
      resetType: settings.rolloverResetType,
      now: now,
      anchorFrequency: anchor?.frequency,
      anchorNextPaydayDate: anchor?.nextPaydayDate,
    );

    final balance = await _txnRepo.computeBalance();
    final allTxns = await _txnRepo.getByDateRange(cycle.start, cycle.end);
    final incomeTxns = allTxns.where((t) => t.type == 'income').toList();
    final billPaidTxns =
        allTxns.where((t) => t.linkedBillId != null).toList();

    final schedules = await _incomeRepo.getAll();
    final bills = await _billsRepo.getAll();

    final projectedIncome = ProjectionService.projectIncome(
      start: todayStart, end: cycle.end,
      confirmedIncome: incomeTxns, schedules: schedules,
    );
    final projectedBills = ProjectionService.projectBills(
      start: todayStart, end: cycle.end,
      bills: bills, paidBillTransactions: billPaidTxns,
    );

    final available = balance + projectedIncome - projectedBills;
    final daysLeft = cycle.daysLeft;
    final dailyBase = available > 0 ? available / daysLeft : 0.0;

    final banked = _computeBanked(
      allTxns: allTxns, dailyBase: dailyBase,
      cycleStart: cycle.start, todayStart: todayStart,
    );

    final rawAllowance = dailyBase + banked;
    final allowanceToday = rawAllowance > 0 ? rawAllowance : 0.0;
    final behindAmount = available < 0
        ? available.abs()
        : (rawAllowance < 0 ? rawAllowance.abs() : 0.0);

    return PaycheckAllowanceResult(
      balance: balance, allowanceToday: allowanceToday,
      bankedAllowance: banked, behindAmount: behindAmount,
      projectedIncome: projectedIncome, projectedBills: projectedBills,
      daysLeft: daysLeft, cycleWindow: cycle,
    );
  }

  // ── Goal mode (PRD 5.9) ──

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
    final h = horizon < 1 ? 1 : horizon;
    final horizonEnd = DateTime(
        todayStart.year, todayStart.month, todayStart.day + h);

    final anchor = await _incomeRepo.getAnchor();
    final cycle = CycleWindowCalculator.compute(
      resetType: settings.rolloverResetType, now: now,
      anchorFrequency: anchor?.frequency,
      anchorNextPaydayDate: anchor?.nextPaydayDate,
    );

    final balance = await _txnRepo.computeBalance();
    final allTxns = await _txnRepo.getByDateRange(cycle.start, cycle.end);
    final incomeTxns = allTxns.where((t) => t.type == 'income').toList();
    final billPaidTxns =
        allTxns.where((t) => t.linkedBillId != null).toList();

    final schedules = await _incomeRepo.getAll();
    final bills = await _billsRepo.getAll();

    final projectedIncome = ProjectionService.projectIncome(
      start: todayStart, end: horizonEnd,
      confirmedIncome: incomeTxns, schedules: schedules,
    );
    final projectedBills = ProjectionService.projectBills(
      start: todayStart, end: horizonEnd,
      bills: bills, paidBillTransactions: billPaidTxns,
    );

    final style = enumFromDb<SavingStyle>(
        goal.savingStyle, SavingStyle.values);
    final vd = _computeBaselineDailySpend(
      allTxns: await _txnRepo.getAll(),
      windowDays: settings.spendingBaselineDays,
    );
    final allowedVarPerDay = style.multiplier * vd;

    final feasibility = GoalFeasibilityService.compute(
      goal: goal, balance: balance,
      projectedIncome: projectedIncome, projectedBills: projectedBills,
      dailyVariableSpend: vd, savingStyleMultiplier: style.multiplier,
    );

    // Banked: shared, computed from cycle (same as paycheck)
    final banked = _computeBanked(
      allTxns: allTxns, dailyBase: allowedVarPerDay,
      cycleStart: cycle.start, todayStart: todayStart,
    );

    final rawAllowance = allowedVarPerDay + banked;
    final allowanceToday = rawAllowance > 0 ? rawAllowance : 0.0;
    final behindAmount = !feasibility.isFeasible
        ? feasibility.deficit
        : (rawAllowance < 0 ? rawAllowance.abs() : 0.0);

    return GoalAllowanceResult(
      balance: balance, allowanceToday: allowanceToday,
      bankedAllowance: banked, behindAmount: behindAmount,
      projectedIncome: projectedIncome, projectedBills: projectedBills,
      daysToGoal: h, goal: goal,
      feasibility: feasibility, cycleWindow: cycle,
    );
  }

  // ── Shared helpers ──

  double _computeBanked({
    required List<Transaction> allTxns,
    required double dailyBase,
    required DateTime cycleStart,
    required DateTime todayStart,
  }) {
    double banked = 0;
    var day = DateTime(cycleStart.year, cycleStart.month, cycleStart.day);

    while (day.isBefore(todayStart)) {
      final nextDay = DateTime(day.year, day.month, day.day + 1);
      double daySpend = 0;
      for (final txn in allTxns) {
        final txnDay = DateTime(txn.date.year, txn.date.month, txn.date.day);
        if (txnDay == day && txn.type == 'expense') {
          daySpend += txn.amount;
        }
      }
      banked += (dailyBase - daySpend);
      day = nextDay;
    }
    return banked;
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
  /// Uses monthly cycle: allowance for the day = dailyBase + banked from month start.
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

    final banked = _computeBanked(
      allTxns: allTxns,
      dailyBase: dailyBase,
      cycleStart: monthStart,
      todayStart: dayStart,
    );

    final allowanceForDay = dailyBase + banked;
    double spendOnDay = 0;
    for (final t in allTxns) {
      final tDay = DateTime(t.date.year, t.date.month, t.date.day);
      if (tDay == dayStart && t.type == 'expense') spendOnDay += t.amount;
    }

    return spendOnDay <= allowanceForDay;
  }
}
