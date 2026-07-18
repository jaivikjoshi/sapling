import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/repositories/transactions_repository.dart';
import '../models/enums.dart';
import '../models/settings_model.dart';
import 'allowance_engine.dart';
import 'cycle_window_calculator.dart';

class FinanceSummary {
  const FinanceSummary({
    required this.computedAt,
    required this.currency,
    required this.mode,
    required this.usedGoalFallback,
    required this.cycleWindow,
    required this.balance,
    required this.incomeThisCycle,
    required this.expensesThisCycle,
    required this.adjustmentsThisCycle,
    required this.projectedIncome,
    required this.projectedBills,
    required this.spendablePool,
    required this.dailyAllowance,
    required this.spentToday,
    required this.safeToSpendToday,
    required this.behindAmount,
    required this.remainingDays,
  });

  final DateTime computedAt;
  final Currency currency;
  final AllowanceMode mode;
  final bool usedGoalFallback;
  final CycleWindow cycleWindow;
  final double balance;
  final double incomeThisCycle;
  final double expensesThisCycle;
  final double adjustmentsThisCycle;
  final double projectedIncome;
  final double projectedBills;
  final double spendablePool;
  final double dailyAllowance;
  final double spentToday;
  final double safeToSpendToday;
  final double behindAmount;
  final int remainingDays;

  double get netThisCycle =>
      incomeThisCycle + adjustmentsThisCycle - expensesThisCycle;

  bool get isBehind => behindAmount > 0.005;

  List<FinanceSummaryLine> explain() {
    return [
      FinanceSummaryLine(label: 'Current balance', amount: balance),
      FinanceSummaryLine(
        label: 'Income still expected',
        amount: projectedIncome,
      ),
      FinanceSummaryLine(label: 'Bills reserved', amount: -projectedBills),
      FinanceSummaryLine(label: 'Spendable pool', amount: spendablePool),
      FinanceSummaryLine(label: 'Daily allowance', amount: dailyAllowance),
      FinanceSummaryLine(label: 'Spent today', amount: -spentToday),
      FinanceSummaryLine(
        label: 'Safe to spend today',
        amount: safeToSpendToday,
      ),
    ];
  }
}

class FinanceSummaryLine {
  const FinanceSummaryLine({required this.label, required this.amount});

  final String label;
  final double amount;
}

class FinanceSummaryService {
  const FinanceSummaryService({
    required AllowanceEngine allowanceEngine,
    required TransactionsRepository transactionsRepository,
  }) : _allowanceEngine = allowanceEngine,
       _transactionsRepository = transactionsRepository;

  final AllowanceEngine _allowanceEngine;
  final TransactionsRepository _transactionsRepository;

  Future<FinanceSummary> compute({
    required UserSettings settings,
    AllowanceMode? modeOverride,
  }) async {
    final requestedMode = modeOverride ?? settings.allowanceDefaultMode;
    final goalResult =
        requestedMode == AllowanceMode.goal
            ? await _allowanceEngine.computeGoalMode(settings: settings)
            : null;
    final usedGoalFallback =
        requestedMode == AllowanceMode.goal && goalResult == null;
    final paycheckResult =
        goalResult == null
            ? await _allowanceEngine.computePaycheckMode(settings: settings)
            : null;

    final cycleWindow = goalResult?.cycleWindow ?? paycheckResult!.cycleWindow;
    final postedCycleTransactions =
        (await _transactionsRepository.getByDateRange(
          cycleWindow.start,
          cycleWindow.end,
        )).where((txn) => !txn.date.isAfter(DateTime.now())).toList();

    final totals = _cycleTotals(postedCycleTransactions);
    return FinanceSummary(
      computedAt: DateTime.now(),
      currency: settings.baseCurrency,
      mode: goalResult == null ? AllowanceMode.paycheck : AllowanceMode.goal,
      usedGoalFallback: usedGoalFallback,
      cycleWindow: cycleWindow,
      balance: goalResult?.balance ?? paycheckResult!.balance,
      incomeThisCycle: totals.income,
      expensesThisCycle: totals.expenses,
      adjustmentsThisCycle: totals.adjustments,
      projectedIncome:
          goalResult?.projectedIncome ?? paycheckResult!.projectedIncome,
      projectedBills:
          goalResult?.projectedBills ?? paycheckResult!.projectedBills,
      spendablePool: goalResult?.spendablePool ?? paycheckResult!.spendablePool,
      dailyAllowance:
          goalResult?.dailyAllowance ?? paycheckResult!.dailyAllowance,
      spentToday: goalResult?.todaySpend ?? paycheckResult!.todaySpend,
      safeToSpendToday:
          goalResult?.remainingToday ?? paycheckResult!.remainingToday,
      behindAmount: goalResult?.behindAmount ?? paycheckResult!.behindAmount,
      remainingDays: goalResult?.daysToGoal ?? paycheckResult!.daysLeft,
    );
  }

  _CycleTotals _cycleTotals(List<Transaction> transactions) {
    var income = 0.0;
    var expenses = 0.0;
    var adjustments = 0.0;
    for (final txn in transactions) {
      final type = enumFromDb<TransactionType>(
        txn.type,
        TransactionType.values,
      );
      switch (type) {
        case TransactionType.income:
          income += txn.amount;
        case TransactionType.expense:
          expenses += txn.amount;
        case TransactionType.adjustment:
          adjustments += txn.amount;
      }
    }
    return _CycleTotals(
      income: income,
      expenses: expenses,
      adjustments: adjustments,
    );
  }
}

class _CycleTotals {
  const _CycleTotals({
    required this.income,
    required this.expenses,
    required this.adjustments,
  });

  final double income;
  final double expenses;
  final double adjustments;
}
