import 'dart:math' as math;

import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/goals_repository.dart';
import '../../data/repositories/recurring_income_repository.dart';
import '../../data/repositories/recovery_plans_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../models/enums.dart';
import '../models/settings_model.dart';
import 'allowance_engine.dart';
import 'closeout_service.dart';
import 'cycle_window_calculator.dart';
import 'projection_service.dart';
import 'recovery_plan_service.dart';

/// Date bucketing uses local timezone (DateTime without UTC).
class ReportsService {
  final TransactionsRepository _txnRepo;
  final CategoriesRepository _categoriesRepo;
  final BillsRepository _billsRepo;
  final RecurringIncomeRepository _incomeRepo;
  final GoalsRepository _goalsRepo;
  final SettingsRepository _settingsRepo;
  final AllowanceEngine _allowanceEngine;
  final CloseoutService _closeoutService;
  final RecoveryPlansRepository _recoveryPlansRepo;

  ReportsService(
    this._txnRepo,
    this._categoriesRepo,
    this._billsRepo,
    this._incomeRepo,
    this._goalsRepo,
    this._settingsRepo,
    this._allowanceEngine,
    this._closeoutService,
    this._recoveryPlansRepo,
  );

  /// Start of month in local time (inclusive). End is start of next month (exclusive).
  static DateTime monthStart(int year, int month) => DateTime(year, month, 1);

  static DateTime monthEnd(int year, int month) => DateTime(year, month + 1, 1);

  static DateTime yearStart(int year) => DateTime(year, 1, 1);
  static DateTime yearEnd(int year) => DateTime(year + 1, 1, 1);

  Future<MonthlySummary> monthlySummary(int year, int month) async {
    final start = monthStart(year, month);
    final end = monthEnd(year, month);
    final txns = await _txnRepo.getByDateRange(start, end);
    return _summarize(txns);
  }

  Future<AnnualSummary> annualSummary(int year) async {
    final start = yearStart(year);
    final end = yearEnd(year);
    final txns = await _txnRepo.getByDateRange(start, end);
    final s = await _summarize(txns);
    return AnnualSummary(
      year: year,
      incomeTotal: s.incomeTotal,
      expenseTotal: s.expenseTotal,
      adjustmentTotal: s.adjustmentTotal,
      net: s.net,
    );
  }

  Future<MonthlySummary> _summarize(List<Transaction> txns) async {
    double income = 0, expense = 0, adjustment = 0;
    for (final t in txns) {
      switch (t.type) {
        case 'income':
          income += t.amount;
          break;
        case 'expense':
          expense += t.amount;
          break;
        case 'adjustment':
          adjustment += t.amount;
          break;
      }
    }
    return MonthlySummary(
      incomeTotal: income,
      expenseTotal: expense,
      adjustmentTotal: adjustment,
      net: income - expense + adjustment,
    );
  }

  Future<MonthlySummary> periodSummary(DateTime start, DateTime end) async {
    final txns = await _txnRepo.getByDateRange(start, end);
    return _summarize(txns);
  }

  Future<List<Transaction>> getTransactionsInPeriod(
    DateTime start,
    DateTime end,
  ) async {
    return _txnRepo.getByDateRange(start, end);
  }

  /// Per-category expense total for the month. Only expenses with categoryId.
  Future<List<CategoryBreakdownItem>> categoryBreakdown(int year, int month) async {
    final start = monthStart(year, month);
    final end = monthEnd(year, month);
    return categoryBreakdownByPeriod(start, end);
  }

  /// Per-category expense total for a custom period.
  Future<List<CategoryBreakdownItem>> categoryBreakdownByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final txns = await _txnRepo.getByDateRange(start, end);
    final byCategory = <String, double>{};
    for (final t in txns) {
      if (t.type != 'expense' || t.categoryId == null) continue;
      byCategory[t.categoryId!] = (byCategory[t.categoryId!] ?? 0) + t.amount;
    }
    final categories = await _categoriesRepo.getAll();
    final nameById = {for (final c in categories) c.id: c.name};
    return byCategory.entries
        .map(
          (e) => CategoryBreakdownItem(
            categoryId: e.key,
            categoryName: nameById[e.key] ?? e.key,
            total: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  /// Bills count when paid: expenses with linkedBillId in [start, end).
  Future<BillsPaidInPeriodResult> billsPaidInPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final txns = await _txnRepo.getByDateRange(start, end);
    final paid = txns
        .where((t) => t.type == 'expense' && t.linkedBillId != null)
        .toList();
    final count = paid.length;
    final total = paid.fold<double>(0, (s, t) => s + t.amount);
    return BillsPaidInPeriodResult(count: count, totalAmount: total);
  }

  Future<List<ReportPeriodOption>> availablePeriods(
    ReportTimeframe timeframe, {
    int count = 12,
  }) async {
    switch (timeframe) {
      case ReportTimeframe.month:
        return _availableMonths(count);
      case ReportTimeframe.year:
        return _availableYears(count);
      case ReportTimeframe.cycle:
        return _availableCycles(count);
    }
  }

  Future<ReportsSnapshot> buildSnapshot(ReportsRequest request) async {
    final settings = UserSettings.fromDb(await _settingsRepo.get());
    final allCategories = await _categoriesRepo.getAll();
    final categoryById = {for (final category in allCategories) category.id: category};
    final allBills = await _billsRepo.getAll();
    final billById = {for (final bill in allBills) bill.id: bill};
    final incomes = await _incomeRepo.getAll();
    final incomeById = {for (final income in incomes) income.id: income};
    final goals = await _goalsRepo.getAll();
    final goalById = {for (final goal in goals) goal.id: goal};

    final transactions = await _txnRepo.getByDateRange(
      request.period.start,
      request.period.end,
    );
    final summary = await _summarize(transactions);

    final previousPeriod = request.comparisonMode == ReportComparisonMode.previousPeriod
        ? await _previousPeriod(request.period, settings)
        : null;
    final previousTransactions = previousPeriod == null
        ? const <Transaction>[]
        : await _txnRepo.getByDateRange(previousPeriod.start, previousPeriod.end);
    final previousSummary = previousTransactions.isEmpty
        ? null
        : await _summarize(previousTransactions);

    final budgetBasis =
        math.max(0.0, summary.incomeTotal + summary.adjustmentTotal).toDouble();
    final elapsedDays = _elapsedDays(request.period);
    final totalDays = _periodLengthDays(request.period.start, request.period.end);
    final remainingDays = math.max(totalDays - elapsedDays, 0);
    final expectedSpendByNow = totalDays > 0
        ? budgetBasis * (elapsedDays / totalDays)
        : 0.0;
    final safeRemaining = budgetBasis - summary.expenseTotal;
    final paceDelta = summary.expenseTotal - expectedSpendByNow;
    final paceStatus = _paceStatus(
      safeRemaining: safeRemaining,
      expenseTotal: summary.expenseTotal,
      expectedSpendByNow: expectedSpendByNow,
    );

    final chart = _buildChart(
      period: request.period,
      transactions: transactions,
      budgetBasis: budgetBasis,
    );

    final expenseTransactions =
        transactions.where((txn) => txn.type == 'expense').toList();
    final incomeTransactions =
        transactions.where((txn) => txn.type == 'income').toList();
    final paidBillTransactions =
        expenseTransactions.where((txn) => txn.linkedBillId != null).toList();

    final spending = _buildSpendingSection(
      transactions: transactions,
      previousTransactions: previousTransactions,
      categoryById: categoryById,
      totalExpense: summary.expenseTotal,
      totalDays: totalDays,
    );

    final labels = _buildLabelSection(
      expenseTransactions: expenseTransactions,
      categoryById: categoryById,
      totalExpense: summary.expenseTotal,
    );

    final income = _buildIncomeSection(
      incomeTransactions: incomeTransactions,
      incomeById: incomeById,
    );

    final bills = await _buildBillsSection(
      period: request.period,
      paidBillTransactions: paidBillTransactions,
      allBills: allBills,
      billById: billById,
      categoryById: categoryById,
    );

    final goal = await _buildGoalSection(
      settings: settings,
      summary: summary,
      request: request,
      goalById: goalById,
    );

    final allowance = await _buildAllowanceSection(
      request: request,
      settings: settings,
      period: request.period,
      summary: summary,
      transactions: transactions,
      totalDays: totalDays,
      budgetBasis: budgetBasis,
    );

    final streak = await _closeoutService
        .computeStreak(settings: settings)
        .timeout(
          const Duration(milliseconds: 900),
          onTimeout: () =>
              const StreakResult(currentStreak: 0, todayWithinBudget: false),
        );
    final activeRecovery = await _recoveryPlansRepo.getActive();
    final habits = _buildHabitsSection(
      period: request.period,
      expenseTransactions: expenseTransactions,
      targetPerDay: allowance.dailyTargetForPeriod,
      currentStreak: streak.currentStreak,
      todayWithinBudget: streak.todayWithinBudget,
      activeRecovery: activeRecovery,
    );

    final comparison = previousSummary == null
        ? null
        : ReportComparisonSummary(
            previousLabel: previousPeriod!.label,
            expenseDelta: summary.expenseTotal - previousSummary.expenseTotal,
            incomeDelta: summary.incomeTotal - previousSummary.incomeTotal,
            expenseChangePercent: previousSummary.expenseTotal > 0
                ? ((summary.expenseTotal - previousSummary.expenseTotal) /
                        previousSummary.expenseTotal) *
                    100
                : null,
          );

    return ReportsSnapshot(
      period: request.period,
      summary: summary,
      hero: ReportHeroSummary(
        spentSoFar: summary.expenseTotal,
        safeRemaining: safeRemaining,
        status: paceStatus,
        paceDelta: paceDelta,
        comparison: comparison,
      ),
      chart: chart,
      earnedThisPeriod: summary.incomeTotal,
      spentThisPeriod: summary.expenseTotal,
      netFlow: summary.net,
      dailyAllowed: allowance.currentDailyAllowance,
      currentPace: elapsedDays > 0 ? summary.expenseTotal / elapsedDays : 0.0,
      projectedEndSpend: chart.projectedEndSpend,
      bankedAllowance: allowance.bankedBuilt - allowance.bankedUsed,
      daysLeftInPeriod: remainingDays,
      noSpendDays: habits.noSpendDays,
      goalFundingRoom: goal.fundingRoomThisPeriod,
      spending: spending,
      labels: labels,
      income: income,
      bills: bills,
      goal: goal,
      allowance: allowance,
      habits: habits,
    );
  }

  Future<List<Transaction>> transactionsForDrilldown(
    ReportDrilldownQuery query,
  ) async {
    final transactions = await _txnRepo.getByDateRange(query.start, query.end);
    final categories = await _categoriesRepo.getAll();
    final categoryById = {for (final category in categories) category.id: category};

    final filtered = transactions.where((txn) {
      if (query.expensesOnly && txn.type != 'expense') return false;
      if (query.incomeOnly && txn.type != 'income') return false;
      if (query.adjustmentsOnly && txn.type != 'adjustment') return false;
      if (query.billOnly && txn.linkedBillId == null) return false;
      if (query.linkedBillId != null && txn.linkedBillId != query.linkedBillId) {
        return false;
      }
      if (query.categoryId != null && txn.categoryId != query.categoryId) {
        return false;
      }
      if (query.recurringIncomeOnly && txn.linkedRecurringIncomeId == null) {
        return false;
      }
      if (query.oneTimeIncomeOnly && txn.linkedRecurringIncomeId != null) {
        return false;
      }
      if (query.spendLabel != null) {
        final label = _resolvedLabel(txn, categoryById);
        if (label != query.spendLabel) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  Future<List<ReportDrilldownRow>> billDrilldownRows(
    ReportPeriodOption period,
  ) async {
    final transactions = await _txnRepo.getByDateRange(period.start, period.end);
    final bills = await _billsRepo.getAll();
    final billById = {for (final bill in bills) bill.id: bill};
    final totals = <String, double>{};
    for (final txn in transactions) {
      if (txn.type != 'expense' || txn.linkedBillId == null) continue;
      totals[txn.linkedBillId!] = (totals[txn.linkedBillId!] ?? 0) + txn.amount;
    }
    final rows = totals.entries
        .map(
          (entry) => ReportDrilldownRow(
            id: entry.key,
            title: billById[entry.key]?.name ?? 'Bill',
            subtitle: '${entry.value.toStringAsFixed(2)} paid',
            amount: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return rows;
  }

  Future<List<ReportPeriodOption>> _availableMonths(int count) async {
    final now = DateTime.now();
    return List.generate(count, (index) {
      final month = DateTime(now.year, now.month - index, 1);
      return ReportPeriodOption(
        id: 'month-${month.year}-${month.month}',
        timeframe: ReportTimeframe.month,
        start: DateTime(month.year, month.month, 1),
        end: DateTime(month.year, month.month + 1, 1),
        label: _monthLabel(month),
        caption: _rangeCaption(
          DateTime(month.year, month.month, 1),
          DateTime(month.year, month.month + 1, 1),
        ),
        isCurrent: index == 0,
      );
    });
  }

  Future<List<ReportPeriodOption>> _availableYears(int count) async {
    final now = DateTime.now();
    return List.generate(count, (index) {
      final year = now.year - index;
      return ReportPeriodOption(
        id: 'year-$year',
        timeframe: ReportTimeframe.year,
        start: DateTime(year, 1, 1),
        end: DateTime(year + 1, 1, 1),
        label: '$year',
        caption: 'Jan 1 - Dec 31',
        isCurrent: index == 0,
      );
    });
  }

  Future<List<ReportPeriodOption>> _availableCycles(int count) async {
    final settings = UserSettings.fromDb(await _settingsRepo.get());
    final anchor = await _incomeRepo.getAnchor();
    var cycle = CycleWindowCalculator.compute(
      resetType: settings.rolloverResetType,
      now: DateTime.now(),
      anchorFrequency: anchor?.frequency,
      anchorNextPaydayDate: anchor?.nextPaydayDate,
    );

    final periods = <ReportPeriodOption>[];
    for (var index = 0; index < count; index++) {
      periods.add(
        ReportPeriodOption(
          id: 'cycle-${cycle.start.toIso8601String()}',
          timeframe: ReportTimeframe.cycle,
          start: cycle.start,
          end: cycle.end,
          label: _cycleLabel(cycle.start, cycle.end),
          caption: _rangeCaption(cycle.start, cycle.end),
          isCurrent: index == 0,
        ),
      );
      cycle = CycleWindow(
        start: _previousCycleStart(
          cycle.start,
          settings.rolloverResetType,
          anchor?.frequency,
        ),
        end: cycle.start,
      );
    }

    return periods;
  }

  Future<ReportPeriodOption?> _previousPeriod(
    ReportPeriodOption period,
    UserSettings settings,
  ) async {
    switch (period.timeframe) {
      case ReportTimeframe.month:
        final start = DateTime(period.start.year, period.start.month - 1, 1);
        final end = DateTime(period.start.year, period.start.month, 1);
        return ReportPeriodOption(
          id: 'month-${start.year}-${start.month}',
          timeframe: ReportTimeframe.month,
          start: start,
          end: end,
          label: _monthLabel(start),
          caption: _rangeCaption(start, end),
          isCurrent: false,
        );
      case ReportTimeframe.year:
        final year = period.start.year - 1;
        return ReportPeriodOption(
          id: 'year-$year',
          timeframe: ReportTimeframe.year,
          start: DateTime(year, 1, 1),
          end: DateTime(year + 1, 1, 1),
          label: '$year',
          caption: 'Jan 1 - Dec 31',
          isCurrent: false,
        );
      case ReportTimeframe.cycle:
        final anchor = await _incomeRepo.getAnchor();
        final start = _previousCycleStart(
          period.start,
          settings.rolloverResetType,
          anchor?.frequency,
        );
        return ReportPeriodOption(
          id: 'cycle-${start.toIso8601String()}',
          timeframe: ReportTimeframe.cycle,
          start: start,
          end: period.start,
          label: _cycleLabel(start, period.start),
          caption: _rangeCaption(start, period.start),
          isCurrent: false,
        );
    }
  }

  ReportChartModel _buildChart({
    required ReportPeriodOption period,
    required List<Transaction> transactions,
    required double budgetBasis,
  }) {
    final buckets = _bucketStarts(period);
    if (buckets.isEmpty) {
      return const ReportChartModel(
        spend: [],
        pace: [],
        income: [],
        projectedSpend: [],
        xLabels: [],
        maxY: 1,
        projectedEndSpend: 0,
      );
    }

    final expenseByBucket = <DateTime, double>{};
    final incomeByBucket = <DateTime, double>{};
    for (final txn in transactions) {
      final bucket = _bucketFor(period.timeframe, txn.date);
      if (txn.type == 'expense') {
        expenseByBucket[bucket] = (expenseByBucket[bucket] ?? 0) + txn.amount;
      } else if (txn.type == 'income') {
        incomeByBucket[bucket] = (incomeByBucket[bucket] ?? 0) + txn.amount;
      }
    }

    final elapsedBuckets = _elapsedBucketCount(period, buckets);
    final totalBuckets = buckets.length;
    double cumulativeSpend = 0;
    double cumulativeIncome = 0;
    final spendPoints = <ReportChartPoint>[];
    final pacePoints = <ReportChartPoint>[];
    final incomePoints = <ReportChartPoint>[];
    final projectedPoints = <ReportChartPoint>[];

    for (var index = 0; index < buckets.length; index++) {
      final bucket = buckets[index];
      cumulativeSpend += expenseByBucket[bucket] ?? 0;
      cumulativeIncome += incomeByBucket[bucket] ?? 0;
      final x = index.toDouble();
      final label = _bucketLabel(period.timeframe, bucket);

      if (index < elapsedBuckets) {
        spendPoints.add(ReportChartPoint(x: x, y: cumulativeSpend, label: label));
        incomePoints.add(ReportChartPoint(x: x, y: cumulativeIncome, label: label));
      }

      final progress = totalBuckets > 0 ? (index + 1) / totalBuckets : 0.0;
      pacePoints.add(
        ReportChartPoint(
          x: x,
          y: budgetBasis * progress,
          label: label,
        ),
      );
    }

    final spentSoFar = spendPoints.isEmpty ? 0.0 : spendPoints.last.y;
    final projectedEndSpend = elapsedBuckets > 0
        ? spentSoFar / elapsedBuckets * totalBuckets
        : 0.0;

    for (var index = 0; index < buckets.length; index++) {
      final x = index.toDouble();
      final label = _bucketLabel(period.timeframe, buckets[index]);
      if (index < elapsedBuckets && spendPoints.length > index) {
        projectedPoints.add(spendPoints[index]);
      } else {
        final futureProgress = totalBuckets <= elapsedBuckets
            ? 1.0
            : (index + 1 - elapsedBuckets) / (totalBuckets - elapsedBuckets);
        projectedPoints.add(
          ReportChartPoint(
            x: x,
            y: spentSoFar +
                ((projectedEndSpend - spentSoFar) * futureProgress.clamp(0.0, 1.0)),
            label: label,
          ),
        );
      }
    }

    final maxY = [
      ...spendPoints.map((point) => point.y),
      ...pacePoints.map((point) => point.y),
      ...incomePoints.map((point) => point.y),
      ...projectedPoints.map((point) => point.y),
      1.0,
    ].reduce(math.max);

    final labelIndexes = <int>{0, buckets.length ~/ 2, buckets.length - 1};
    final xLabels = labelIndexes
        .map((index) => ReportAxisLabel(x: index.toDouble(), label: _bucketLabel(period.timeframe, buckets[index])))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return ReportChartModel(
      spend: spendPoints,
      pace: pacePoints,
      income: incomePoints,
      projectedSpend: projectedPoints,
      xLabels: xLabels,
      maxY: (maxY * 1.12).toDouble(),
      projectedEndSpend: projectedEndSpend,
    );
  }

  ReportSpendingSection _buildSpendingSection({
    required List<Transaction> transactions,
    required List<Transaction> previousTransactions,
    required Map<String, Category> categoryById,
    required double totalExpense,
    required int totalDays,
  }) {
    final currentTotals = <String, double>{};
    final previousTotals = <String, double>{};
    Transaction? biggestExpense;
    final spendingDays = <DateTime>{};

    for (final txn in transactions) {
      if (txn.type != 'expense') continue;
      if (txn.categoryId != null) {
        currentTotals[txn.categoryId!] = (currentTotals[txn.categoryId!] ?? 0) + txn.amount;
      }
      if (biggestExpense == null || txn.amount > biggestExpense.amount) {
        biggestExpense = txn;
      }
      spendingDays.add(_dayBucket(txn.date));
    }

    for (final txn in previousTransactions) {
      if (txn.type != 'expense' || txn.categoryId == null) continue;
      previousTotals[txn.categoryId!] = (previousTotals[txn.categoryId!] ?? 0) + txn.amount;
    }

    final topCategories = currentTotals.entries
        .map(
          (entry) {
            final previousTotal = previousTotals[entry.key] ?? 0;
            final percentOfSpend = totalExpense > 0 ? entry.value / totalExpense : 0.0;
            final trendAmount = entry.value - previousTotal;
            final trendPercent = previousTotal > 0 ? (trendAmount / previousTotal) * 100 : null;
            return ReportCategoryBreakdown(
              categoryId: entry.key,
              categoryName: categoryById[entry.key]?.name ?? 'Uncategorized',
              total: entry.value,
              share: percentOfSpend,
              trendAmount: trendAmount,
              trendPercent: trendPercent,
            );
          },
        )
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return ReportSpendingSection(
      topCategories: topCategories.take(5).toList(),
      biggestExpenseAmount: biggestExpense?.amount ?? 0,
      biggestExpenseTitle: _transactionTitle(biggestExpense, categoryById),
      averageDailySpend: totalDays > 0 ? totalExpense / totalDays : 0.0,
      spendingDays: spendingDays.length,
    );
  }

  ReportLabelSection _buildLabelSection({
    required List<Transaction> expenseTransactions,
    required Map<String, Category> categoryById,
    required double totalExpense,
  }) {
    final totals = <SpendLabel, double>{
      SpendLabel.green: 0,
      SpendLabel.orange: 0,
      SpendLabel.red: 0,
    };

    for (final txn in expenseTransactions) {
      final label = _resolvedLabel(txn, categoryById);
      totals[label] = (totals[label] ?? 0) + txn.amount;
    }

    return ReportLabelSection(
      items: SpendLabel.values
          .map(
            (label) => ReportLabelBreakdown(
              label: label,
              total: totals[label] ?? 0,
              share: totalExpense > 0 ? (totals[label] ?? 0) / totalExpense : 0.0,
            ),
          )
          .toList(),
    );
  }

  ReportIncomeSection _buildIncomeSection({
    required List<Transaction> incomeTransactions,
    required Map<String, RecurringIncome> incomeById,
  }) {
    double recurringTotal = 0;
    double oneTimeTotal = 0;
    double expectedAutoPosted = 0;
    double confirmedActual = 0;
    double expectedReference = 0;
    var paydayCount = 0;

    for (final txn in incomeTransactions) {
      paydayCount++;
      final postingType = txn.incomePostingType == null
          ? null
          : enumFromDb<IncomePostingType>(
              txn.incomePostingType!,
              IncomePostingType.values,
            );
      if (txn.linkedRecurringIncomeId != null) {
        recurringTotal += txn.amount;
        expectedReference += incomeById[txn.linkedRecurringIncomeId!]?.expectedAmount ?? 0;
      } else {
        oneTimeTotal += txn.amount;
      }

      if (postingType == IncomePostingType.autoPostedExpected) {
        expectedAutoPosted += txn.amount;
      } else {
        confirmedActual += txn.amount;
      }
    }

    return ReportIncomeSection(
      recurringIncomeTotal: recurringTotal,
      oneTimeIncomeTotal: oneTimeTotal,
      confirmedActualTotal: confirmedActual,
      autoPostedExpectedTotal: expectedAutoPosted,
      paydayCount: paydayCount,
      expectedVariance: confirmedActual - expectedReference,
    );
  }

  Future<ReportBillsSection> _buildBillsSection({
    required ReportPeriodOption period,
    required List<Transaction> paidBillTransactions,
    required List<Bill> allBills,
    required Map<String, Bill> billById,
    required Map<String, Category> categoryById,
  }) async {
    final futureEnd = period.end.add(const Duration(days: 30));
    final futureTransactions = await _txnRepo.getByDateRange(period.end, futureEnd);
    final upcomingLoad = ProjectionService.projectBills(
      start: period.end,
      end: futureEnd,
      bills: allBills,
      paidBillTransactions: futureTransactions
          .where((txn) => txn.type == 'expense' && txn.linkedBillId != null)
          .toList(),
    );

    final paidCategories = <String, double>{};
    for (final txn in paidBillTransactions) {
      final bill = billById[txn.linkedBillId!];
      final categoryId = bill?.categoryId;
      if (categoryId == null) continue;
      paidCategories[categoryId] = (paidCategories[categoryId] ?? 0) + txn.amount;
    }

    final topBillCategories = paidCategories.entries
        .map(
          (entry) => ReportNamedAmount(
            name: categoryById[entry.key]?.name ?? 'Bills',
            amount: entry.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final upcomingCount = allBills.where((bill) {
      return !bill.nextDueDate.isBefore(period.end) && bill.nextDueDate.isBefore(futureEnd);
    }).length;

    return ReportBillsSection(
      paidBillsTotal: paidBillTransactions.fold<double>(0, (sum, txn) => sum + txn.amount),
      paidBillsCount: paidBillTransactions.length,
      upcomingBillLoad: upcomingLoad,
      upcomingBillsCount: upcomingCount,
      topBillCategories: topBillCategories.take(3).toList(),
    );
  }

  Future<ReportGoalSection> _buildGoalSection({
    required UserSettings settings,
    required MonthlySummary summary,
    required ReportsRequest request,
    required Map<String, Goal> goalById,
  }) async {
    final goalId = settings.primaryGoalId;
    final fundingRoom = math.max(summary.net, 0.0).toDouble();
    if (goalId == null || !goalById.containsKey(goalId)) {
      return ReportGoalSection.empty(fundingRoom);
    }

    final balance = await _txnRepo.computeBalance();
    final goal = goalById[goalId]!;
    final allowance = await _allowanceEngine.computeGoalMode(settings: settings);
    final remaining = math.max(goal.targetAmount - balance, 0.0).toDouble();
    final daysToGoal = _daysUntil(goal.targetDate);
    final paceNeeded = daysToGoal > 0 ? remaining / daysToGoal : remaining;

    final status = allowance == null
        ? ReportGoalStatus.tight
        : allowance.feasibility.isFeasible
            ? (paceNeeded > allowance.dailyAllowance ? ReportGoalStatus.tight : ReportGoalStatus.onTrack)
            : ReportGoalStatus.unrealistic;

    final impactLine = switch (status) {
      ReportGoalStatus.onTrack =>
        'Current spending still leaves room for your primary goal.',
      ReportGoalStatus.tight =>
        'This period is still workable, but the goal pace is tightening.',
      ReportGoalStatus.unrealistic =>
        'Current spending is pushing the goal past its realistic pace.',
      ReportGoalStatus.none =>
        'Set a primary goal to connect reports to your plan.',
    };

    return ReportGoalSection(
      hasPrimaryGoal: true,
      goalId: goal.id,
      goalName: goal.name,
      fundingRoomThisPeriod: fundingRoom,
      remainingToGoal: remaining,
      realismStatus: status,
      paceNeededPerDay: paceNeeded,
      suggestedTargetDate: allowance?.feasibility.suggestedDate,
      impactLine: impactLine,
      currentGoalAllowance: allowance?.dailyAllowance ?? 0,
    );
  }

  Future<ReportAllowanceSection> _buildAllowanceSection({
    required ReportsRequest request,
    required UserSettings settings,
    required ReportPeriodOption period,
    required MonthlySummary summary,
    required List<Transaction> transactions,
    required int totalDays,
    required double budgetBasis,
  }) async {
    final paycheckAllowance =
        await _allowanceEngine.computePaycheckMode(settings: settings);
    final goalAllowance = await _allowanceEngine.computeGoalMode(settings: settings);
    final isGoalMode =
        request.allowanceMode == AllowanceMode.goal && goalAllowance != null;

    final targetPerDay = totalDays > 0 ? budgetBasis / totalDays : 0.0;
    final spendByDay = _dailySpend(period.start, period.end, transactions);
    var daysUnder = 0;
    var daysOver = 0;
    double bankedBuilt = 0;
    double bankedUsed = 0;

    var cursor = _dayBucket(period.start);
    final endDay = _dayBucket(period.end);
    while (cursor.isBefore(endDay)) {
      final spend = spendByDay[cursor] ?? 0.0;
      if (spend <= targetPerDay) {
        daysUnder++;
        bankedBuilt += targetPerDay - spend;
      } else {
        daysOver++;
        bankedUsed += spend - targetPerDay;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    final modeImpactTitle = isGoalMode ? 'To goal date' : 'To next cycle';
    final modeImpactValue =
        isGoalMode ? goalAllowance.daysToGoal : paycheckAllowance.daysLeft;
    final currentDailyAllowance = isGoalMode
        ? goalAllowance.dailyAllowance
        : paycheckAllowance.dailyAllowance;
    final modeImpactRemaining = isGoalMode
        ? goalAllowance.spendablePool
        : paycheckAllowance.spendablePool;
    final behindAmount = isGoalMode
        ? goalAllowance.behindAmount
        : paycheckAllowance.behindAmount;
    final spendToday =
        isGoalMode ? goalAllowance.todaySpend : paycheckAllowance.todaySpend;

    return ReportAllowanceSection(
      currentDailyAllowance: currentDailyAllowance,
      averageDailyActualSpend: totalDays > 0 ? summary.expenseTotal / totalDays : 0.0,
      daysUnderAllowance: daysUnder,
      daysOverAllowance: daysOver,
      bankedBuilt: bankedBuilt,
      bankedUsed: bankedUsed,
      modeImpactTitle: modeImpactTitle,
      modeImpactDays: modeImpactValue,
      modeImpactRemaining: modeImpactRemaining,
      behindAmount: behindAmount,
      spendToday: spendToday,
      dailyTargetForPeriod: targetPerDay,
    );
  }

  ReportHabitsSection _buildHabitsSection({
    required ReportPeriodOption period,
    required List<Transaction> expenseTransactions,
    required double targetPerDay,
    required int currentStreak,
    required bool todayWithinBudget,
    required RecoveryPlan? activeRecovery,
  }) {
    final spendByDay = _dailySpend(period.start, period.end, expenseTransactions);
    var noSpendDays = 0;
    var overspendEvents = 0;
    double totalOverspendAmount = 0;

    var cursor = _dayBucket(period.start);
    final endDay = _dayBucket(period.end);
    while (cursor.isBefore(endDay)) {
      final spend = spendByDay[cursor] ?? 0.0;
      if (spend == 0) {
        noSpendDays++;
      }
      if (spend > targetPerDay) {
        overspendEvents++;
        totalOverspendAmount += spend - targetPerDay;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return ReportHabitsSection(
      currentCloseoutStreak: currentStreak,
      todayWithinBudget: todayWithinBudget,
      noSpendDays: noSpendDays,
      overspendEvents: overspendEvents,
      totalOverspendAmount: totalOverspendAmount,
      hasActiveRecoveryPlan: activeRecovery?.status == 'active',
      activeRecoveryAdjustment:
          RecoveryPlanService.computeTodayAdjustment(activeRecovery),
      activeRecoveryType: activeRecovery?.planType,
    );
  }

  List<DateTime> _bucketStarts(ReportPeriodOption period) {
    switch (period.timeframe) {
      case ReportTimeframe.year:
        return List.generate(
          12,
          (index) => DateTime(period.start.year, index + 1, 1),
        );
      case ReportTimeframe.month:
      case ReportTimeframe.cycle:
        final days = _periodLengthDays(period.start, period.end);
        return List.generate(
          days,
          (index) => DateTime(
            period.start.year,
            period.start.month,
            period.start.day + index,
          ),
        );
    }
  }

  DateTime _bucketFor(ReportTimeframe timeframe, DateTime date) {
    return switch (timeframe) {
      ReportTimeframe.year => DateTime(date.year, date.month, 1),
      ReportTimeframe.month || ReportTimeframe.cycle =>
        DateTime(date.year, date.month, date.day),
    };
  }

  String _bucketLabel(ReportTimeframe timeframe, DateTime bucket) {
    switch (timeframe) {
      case ReportTimeframe.year:
        return _shortMonth(bucket);
      case ReportTimeframe.month:
      case ReportTimeframe.cycle:
        return '${_shortMonth(bucket)} ${bucket.day}';
    }
  }

  int _elapsedBucketCount(ReportPeriodOption period, List<DateTime> buckets) {
    final now = DateTime.now();
    if (!now.isAfter(period.start)) return 0;
    if (!now.isBefore(period.end)) return buckets.length;

    return buckets.where((bucket) {
      switch (period.timeframe) {
        case ReportTimeframe.year:
          final bucketEnd = DateTime(bucket.year, bucket.month + 1, 1);
          return bucketEnd.isBefore(now) || _sameMonth(bucket, now);
        case ReportTimeframe.month:
        case ReportTimeframe.cycle:
          final bucketEnd = bucket.add(const Duration(days: 1));
          return bucketEnd.isBefore(now) || _sameDay(bucket, now);
      }
    }).length;
  }

  int _elapsedDays(ReportPeriodOption period) {
    final now = DateTime.now();
    if (!now.isAfter(period.start)) return 0;
    if (!now.isBefore(period.end)) return _periodLengthDays(period.start, period.end);

    return _periodLengthDays(period.start, _dayBucket(now).add(const Duration(days: 1)));
  }

  Map<DateTime, double> _dailySpend(
    DateTime start,
    DateTime end,
    List<Transaction> transactions,
  ) {
    final map = <DateTime, double>{};
    for (final txn in transactions) {
      if (txn.type != 'expense') continue;
      if (txn.date.isBefore(start) || !txn.date.isBefore(end)) continue;
      final bucket = _dayBucket(txn.date);
      map[bucket] = (map[bucket] ?? 0) + txn.amount;
    }
    return map;
  }

  SpendLabel _resolvedLabel(
    Transaction txn,
    Map<String, Category> categoryById,
  ) {
    final raw = txn.label ?? categoryById[txn.categoryId]?.defaultLabel ?? 'green';
    return enumFromDb<SpendLabel>(raw, SpendLabel.values);
  }

  ReportPaceStatus _paceStatus({
    required double safeRemaining,
    required double expenseTotal,
    required double expectedSpendByNow,
  }) {
    if (safeRemaining < 0) return ReportPaceStatus.overspending;
    if (expenseTotal > expectedSpendByNow * 0.95) {
      return ReportPaceStatus.closeToLimit;
    }
    return ReportPaceStatus.underPace;
  }

  String _transactionTitle(
    Transaction? txn,
    Map<String, Category> categoryById,
  ) {
    if (txn == null) return 'No expense yet';
    if (txn.note != null && txn.note!.trim().isNotEmpty) return txn.note!;
    if (txn.categoryId != null) {
      return categoryById[txn.categoryId!]?.name ?? 'Expense';
    }
    return switch (txn.type) {
      'income' => txn.source ?? 'Income',
      'adjustment' => 'Adjustment',
      _ => 'Expense',
    };
  }

  DateTime _previousCycleStart(
    DateTime currentStart,
    RolloverResetType resetType,
    String? anchorFrequency,
  ) {
    switch (resetType) {
      case RolloverResetType.monthly:
        return DateTime(currentStart.year, currentStart.month - 1, 1);
      case RolloverResetType.paydayBased:
        final frequency = enumFromDb<IncomeFrequency>(
          anchorFrequency ?? 'monthly',
          IncomeFrequency.values,
        );
        return _subtractByIncomeFrequency(currentStart, frequency);
    }
  }

  DateTime _subtractByIncomeFrequency(DateTime date, IncomeFrequency frequency) {
    return switch (frequency) {
      IncomeFrequency.weekly =>
        DateTime(date.year, date.month, date.day - 7),
      IncomeFrequency.biweekly =>
        DateTime(date.year, date.month, date.day - 14),
      IncomeFrequency.monthly => DateTime(date.year, date.month - 1, date.day),
    };
  }

  int _periodLengthDays(DateTime start, DateTime end) =>
      _dayBucket(end).difference(_dayBucket(start)).inDays;

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return math.max(target.difference(today).inDays, 1);
  }

  String _monthLabel(DateTime date) => '${_monthName(date)} ${date.year}';

  String _cycleLabel(DateTime start, DateTime end) {
    final inclusiveEnd = end.subtract(const Duration(days: 1));
    if (start.year == inclusiveEnd.year && start.month == inclusiveEnd.month) {
      return '${_shortMonth(start)} ${start.day} - ${inclusiveEnd.day}';
    }
    return '${_shortMonth(start)} ${start.day} - ${_shortMonth(inclusiveEnd)} ${inclusiveEnd.day}';
  }

  String _rangeCaption(DateTime start, DateTime end) {
    final inclusiveEnd = end.subtract(const Duration(days: 1));
    return '${_monthName(start)} ${start.day} - ${_monthName(inclusiveEnd)} ${inclusiveEnd.day}';
  }

  String _monthName(DateTime date) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[date.month - 1];
  }

  String _shortMonth(DateTime date) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[date.month - 1];
  }

  DateTime _dayBucket(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}

class MonthlySummary {
  final double incomeTotal;
  final double expenseTotal;
  final double adjustmentTotal;
  final double net;

  const MonthlySummary({
    required this.incomeTotal,
    required this.expenseTotal,
    required this.adjustmentTotal,
    required this.net,
  });
}

class AnnualSummary {
  final int year;
  final double incomeTotal;
  final double expenseTotal;
  final double adjustmentTotal;
  final double net;

  const AnnualSummary({
    required this.year,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.adjustmentTotal,
    required this.net,
  });
}

class CategoryBreakdownItem {
  final String categoryId;
  final String categoryName;
  final double total;

  const CategoryBreakdownItem({
    required this.categoryId,
    required this.categoryName,
    required this.total,
  });
}

class BillsPaidInPeriodResult {
  final int count;
  final double totalAmount;

  const BillsPaidInPeriodResult({
    required this.count,
    required this.totalAmount,
  });
}

enum ReportTimeframe { cycle, month, year }

enum ReportComparisonMode { previousPeriod, none }

enum ReportPaceStatus { underPace, closeToLimit, overspending }

enum ReportGoalStatus { onTrack, tight, unrealistic, none }

class ReportPeriodOption {
  final String id;
  final ReportTimeframe timeframe;
  final DateTime start;
  final DateTime end;
  final String label;
  final String caption;
  final bool isCurrent;

  const ReportPeriodOption({
    required this.id,
    required this.timeframe,
    required this.start,
    required this.end,
    required this.label,
    required this.caption,
    required this.isCurrent,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportPeriodOption &&
          other.id == id &&
          other.timeframe == timeframe;

  @override
  int get hashCode => Object.hash(id, timeframe);
}

class ReportsRequest {
  final ReportPeriodOption period;
  final ReportComparisonMode comparisonMode;
  final AllowanceMode allowanceMode;

  const ReportsRequest({
    required this.period,
    required this.comparisonMode,
    required this.allowanceMode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportsRequest &&
          other.period == period &&
          other.comparisonMode == comparisonMode &&
          other.allowanceMode == allowanceMode;

  @override
  int get hashCode => Object.hash(period, comparisonMode, allowanceMode);
}

class ReportsSnapshot {
  final ReportPeriodOption period;
  final MonthlySummary summary;
  final ReportHeroSummary hero;
  final ReportChartModel chart;
  final double earnedThisPeriod;
  final double spentThisPeriod;
  final double netFlow;
  final double dailyAllowed;
  final double currentPace;
  final double projectedEndSpend;
  final double bankedAllowance;
  final int daysLeftInPeriod;
  final int noSpendDays;
  final double goalFundingRoom;
  final ReportSpendingSection spending;
  final ReportLabelSection labels;
  final ReportIncomeSection income;
  final ReportBillsSection bills;
  final ReportGoalSection goal;
  final ReportAllowanceSection allowance;
  final ReportHabitsSection habits;

  const ReportsSnapshot({
    required this.period,
    required this.summary,
    required this.hero,
    required this.chart,
    required this.earnedThisPeriod,
    required this.spentThisPeriod,
    required this.netFlow,
    required this.dailyAllowed,
    required this.currentPace,
    required this.projectedEndSpend,
    required this.bankedAllowance,
    required this.daysLeftInPeriod,
    required this.noSpendDays,
    required this.goalFundingRoom,
    required this.spending,
    required this.labels,
    required this.income,
    required this.bills,
    required this.goal,
    required this.allowance,
    required this.habits,
  });
}

class ReportHeroSummary {
  final double spentSoFar;
  final double safeRemaining;
  final ReportPaceStatus status;
  final double paceDelta;
  final ReportComparisonSummary? comparison;

  const ReportHeroSummary({
    required this.spentSoFar,
    required this.safeRemaining,
    required this.status,
    required this.paceDelta,
    required this.comparison,
  });
}

class ReportComparisonSummary {
  final String previousLabel;
  final double expenseDelta;
  final double incomeDelta;
  final double? expenseChangePercent;

  const ReportComparisonSummary({
    required this.previousLabel,
    required this.expenseDelta,
    required this.incomeDelta,
    required this.expenseChangePercent,
  });
}

class ReportChartModel {
  final List<ReportChartPoint> spend;
  final List<ReportChartPoint> pace;
  final List<ReportChartPoint> income;
  final List<ReportChartPoint> projectedSpend;
  final List<ReportAxisLabel> xLabels;
  final double maxY;
  final double projectedEndSpend;

  const ReportChartModel({
    required this.spend,
    required this.pace,
    required this.income,
    required this.projectedSpend,
    required this.xLabels,
    required this.maxY,
    required this.projectedEndSpend,
  });
}

class ReportChartPoint {
  final double x;
  final double y;
  final String label;

  const ReportChartPoint({
    required this.x,
    required this.y,
    required this.label,
  });
}

class ReportAxisLabel {
  final double x;
  final String label;

  const ReportAxisLabel({required this.x, required this.label});
}

class ReportSpendingSection {
  final List<ReportCategoryBreakdown> topCategories;
  final double biggestExpenseAmount;
  final String biggestExpenseTitle;
  final double averageDailySpend;
  final int spendingDays;

  const ReportSpendingSection({
    required this.topCategories,
    required this.biggestExpenseAmount,
    required this.biggestExpenseTitle,
    required this.averageDailySpend,
    required this.spendingDays,
  });
}

class ReportCategoryBreakdown {
  final String categoryId;
  final String categoryName;
  final double total;
  final double share;
  final double trendAmount;
  final double? trendPercent;

  const ReportCategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.total,
    required this.share,
    required this.trendAmount,
    required this.trendPercent,
  });
}

class ReportLabelSection {
  final List<ReportLabelBreakdown> items;

  const ReportLabelSection({required this.items});
}

class ReportLabelBreakdown {
  final SpendLabel label;
  final double total;
  final double share;

  const ReportLabelBreakdown({
    required this.label,
    required this.total,
    required this.share,
  });
}

class ReportIncomeSection {
  final double recurringIncomeTotal;
  final double oneTimeIncomeTotal;
  final double confirmedActualTotal;
  final double autoPostedExpectedTotal;
  final int paydayCount;
  final double expectedVariance;

  const ReportIncomeSection({
    required this.recurringIncomeTotal,
    required this.oneTimeIncomeTotal,
    required this.confirmedActualTotal,
    required this.autoPostedExpectedTotal,
    required this.paydayCount,
    required this.expectedVariance,
  });
}

class ReportBillsSection {
  final double paidBillsTotal;
  final int paidBillsCount;
  final double upcomingBillLoad;
  final int upcomingBillsCount;
  final List<ReportNamedAmount> topBillCategories;

  const ReportBillsSection({
    required this.paidBillsTotal,
    required this.paidBillsCount,
    required this.upcomingBillLoad,
    required this.upcomingBillsCount,
    required this.topBillCategories,
  });
}

class ReportGoalSection {
  final bool hasPrimaryGoal;
  final String? goalId;
  final String? goalName;
  final double fundingRoomThisPeriod;
  final double remainingToGoal;
  final ReportGoalStatus realismStatus;
  final double paceNeededPerDay;
  final DateTime? suggestedTargetDate;
  final String impactLine;
  final double currentGoalAllowance;

  const ReportGoalSection({
    required this.hasPrimaryGoal,
    required this.goalId,
    required this.goalName,
    required this.fundingRoomThisPeriod,
    required this.remainingToGoal,
    required this.realismStatus,
    required this.paceNeededPerDay,
    required this.suggestedTargetDate,
    required this.impactLine,
    required this.currentGoalAllowance,
  });

  factory ReportGoalSection.empty(double fundingRoomThisPeriod) {
    return ReportGoalSection(
      hasPrimaryGoal: false,
      goalId: null,
      goalName: null,
      fundingRoomThisPeriod: fundingRoomThisPeriod,
      remainingToGoal: 0,
      realismStatus: ReportGoalStatus.none,
      paceNeededPerDay: 0,
      suggestedTargetDate: null,
      impactLine: 'Set a primary goal to connect reports to your plan.',
      currentGoalAllowance: 0,
    );
  }
}

class ReportAllowanceSection {
  final double currentDailyAllowance;
  final double averageDailyActualSpend;
  final int daysUnderAllowance;
  final int daysOverAllowance;
  final double bankedBuilt;
  final double bankedUsed;
  final String modeImpactTitle;
  final int modeImpactDays;
  final double modeImpactRemaining;
  final double behindAmount;
  final double spendToday;
  final double dailyTargetForPeriod;

  const ReportAllowanceSection({
    required this.currentDailyAllowance,
    required this.averageDailyActualSpend,
    required this.daysUnderAllowance,
    required this.daysOverAllowance,
    required this.bankedBuilt,
    required this.bankedUsed,
    required this.modeImpactTitle,
    required this.modeImpactDays,
    required this.modeImpactRemaining,
    required this.behindAmount,
    required this.spendToday,
    required this.dailyTargetForPeriod,
  });
}

class ReportHabitsSection {
  final int currentCloseoutStreak;
  final bool todayWithinBudget;
  final int noSpendDays;
  final int overspendEvents;
  final double totalOverspendAmount;
  final bool hasActiveRecoveryPlan;
  final double activeRecoveryAdjustment;
  final String? activeRecoveryType;

  const ReportHabitsSection({
    required this.currentCloseoutStreak,
    required this.todayWithinBudget,
    required this.noSpendDays,
    required this.overspendEvents,
    required this.totalOverspendAmount,
    required this.hasActiveRecoveryPlan,
    required this.activeRecoveryAdjustment,
    required this.activeRecoveryType,
  });
}

class ReportNamedAmount {
  final String name;
  final double amount;

  const ReportNamedAmount({required this.name, required this.amount});
}

class ReportDrilldownQuery {
  final DateTime start;
  final DateTime end;
  final bool expensesOnly;
  final bool incomeOnly;
  final bool adjustmentsOnly;
  final bool billOnly;
  final String? linkedBillId;
  final String? categoryId;
  final SpendLabel? spendLabel;
  final bool recurringIncomeOnly;
  final bool oneTimeIncomeOnly;

  const ReportDrilldownQuery({
    required this.start,
    required this.end,
    this.expensesOnly = false,
    this.incomeOnly = false,
    this.adjustmentsOnly = false,
    this.billOnly = false,
    this.linkedBillId,
    this.categoryId,
    this.spendLabel,
    this.recurringIncomeOnly = false,
    this.oneTimeIncomeOnly = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportDrilldownQuery &&
          other.start == start &&
          other.end == end &&
          other.expensesOnly == expensesOnly &&
          other.incomeOnly == incomeOnly &&
          other.adjustmentsOnly == adjustmentsOnly &&
          other.billOnly == billOnly &&
          other.linkedBillId == linkedBillId &&
          other.categoryId == categoryId &&
          other.spendLabel == spendLabel &&
          other.recurringIncomeOnly == recurringIncomeOnly &&
          other.oneTimeIncomeOnly == oneTimeIncomeOnly;

  @override
  int get hashCode => Object.hash(
        start,
        end,
        expensesOnly,
        incomeOnly,
        adjustmentsOnly,
        billOnly,
        linkedBillId,
        categoryId,
        spendLabel,
        recurringIncomeOnly,
        oneTimeIncomeOnly,
      );
}

class ReportDrilldownRow {
  final String id;
  final String title;
  final String subtitle;
  final double amount;

  const ReportDrilldownRow({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
  });
}
