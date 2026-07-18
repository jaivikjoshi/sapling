import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leko/data/db/leko_database.dart';
import 'package:leko/data/repositories/bills_repository.dart';
import 'package:leko/data/repositories/goals_repository.dart';
import 'package:leko/data/repositories/recurring_income_repository.dart';
import 'package:leko/data/repositories/transactions_repository.dart';
import 'package:leko/domain/models/enums.dart';
import 'package:leko/domain/models/settings_model.dart';
import 'package:leko/domain/services/allowance_engine.dart';
import 'package:leko/domain/services/finance_summary_service.dart';
import 'package:leko/domain/services/ledger_service.dart';

void main() {
  late LekoDatabase db;
  late LedgerService ledger;
  late FinanceSummaryService service;

  setUp(() {
    db = LekoDatabase.forTesting(NativeDatabase.memory());
    final transactions = DriftTransactionsRepository(db);
    final allowanceEngine = AllowanceEngine(
      transactions,
      DriftBillsRepository(db),
      DriftRecurringIncomeRepository(db),
      DriftGoalsRepository(db),
    );
    ledger = LedgerService(transactions);
    service = FinanceSummaryService(
      allowanceEngine: allowanceEngine,
      transactionsRepository: transactions,
    );
  });

  tearDown(() => db.close());

  final settings = UserSettings.defaults.copyWith(
    baseCurrency: Currency.usd,
    onboardingCompleted: true,
  );

  test('summarizes balance, cycle totals, and daily safe-to-spend', () async {
    final now = DateTime.now();
    await ledger.addIncome(
      amount: 1000,
      date: now,
      postingType: IncomePostingType.manualOneTime,
    );
    await ledger.addExpense(
      amount: 75,
      date: now,
      categoryId: 'cat-food',
      label: SpendLabel.green,
    );
    await ledger.addAdjustment(
      amount: 25,
      date: now,
      note: 'Opening balance correction',
    );

    final summary = await service.compute(settings: settings);

    expect(summary.currency, Currency.usd);
    expect(summary.balance, 950);
    expect(summary.incomeThisCycle, 1000);
    expect(summary.expensesThisCycle, 75);
    expect(summary.adjustmentsThisCycle, 25);
    expect(summary.netThisCycle, 950);
    expect(summary.spentToday, 75);
    expect(
      summary.safeToSpendToday,
      closeTo(summary.dailyAllowance - 75, 0.01),
    );
    expect(
      summary.explain().map((line) => line.label),
      contains('Safe to spend today'),
    );
  });

  test(
    'falls back to paycheck mode when goal mode has no primary goal',
    () async {
      await ledger.addIncome(
        amount: 500,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );

      final summary = await service.compute(
        settings: settings.copyWith(allowanceDefaultMode: AllowanceMode.goal),
      );

      expect(summary.mode, AllowanceMode.paycheck);
      expect(summary.usedGoalFallback, isTrue);
      expect(summary.balance, 500);
    },
  );
}
