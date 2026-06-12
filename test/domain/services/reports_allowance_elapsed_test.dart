import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leko/core/utils/enum_serialization.dart';
import 'package:leko/data/db/leko_database.dart';
import 'package:leko/data/repositories/bills_repository.dart';
import 'package:leko/data/repositories/categories_repository.dart';
import 'package:leko/data/repositories/daily_closeouts_repository.dart';
import 'package:leko/data/repositories/goals_repository.dart';
import 'package:leko/data/repositories/recurring_income_repository.dart';
import 'package:leko/data/repositories/recovery_plans_repository.dart';
import 'package:leko/data/repositories/settings_repository.dart';
import 'package:leko/data/repositories/transactions_repository.dart';
import 'package:leko/domain/models/enums.dart';
import 'package:leko/domain/services/allowance_engine.dart';
import 'package:leko/domain/services/closeout_service.dart';
import 'package:leko/domain/services/reports_service.dart';

void main() {
  late LekoDatabase db;
  late ReportsService service;

  setUp(() {
    db = LekoDatabase.forTesting(NativeDatabase.memory());
    final txnRepo = DriftTransactionsRepository(db);
    final categoriesRepo = DriftCategoriesRepository(db);
    final billsRepo = DriftBillsRepository(db);
    final incomeRepo = DriftRecurringIncomeRepository(db);
    final goalsRepo = DriftGoalsRepository(db);
    final settingsRepo = DriftSettingsRepository(db);
    final allowanceEngine = AllowanceEngine(txnRepo, billsRepo, incomeRepo, goalsRepo);
    final closeoutService = CloseoutService(
      DriftDailyCloseoutsRepository(db),
      allowanceEngine,
    );
    service = ReportsService(
      txnRepo,
      categoriesRepo,
      billsRepo,
      incomeRepo,
      goalsRepo,
      settingsRepo,
      allowanceEngine,
      closeoutService,
      DriftRecoveryPlansRepository(db),
    );
  });

  tearDown(() => db.close());

  test('banked allowance excludes future days in the current month', () async {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    final periodEnd = DateTime(now.year, now.month + 1, 1);
    final elapsedDays = now.day;
    final totalDays = periodEnd.difference(periodStart).inDays;

    expect(elapsedDays, lessThan(totalDays));

    final txnRepo = DriftTransactionsRepository(db);
    await txnRepo.insert(Transaction(
      id: 'income-1',
      type: enumToDb(TransactionType.income),
      amount: 3000,
      date: periodStart,
      createdAt: now,
      updatedAt: now,
    ));

    final snapshot = await service.buildSnapshot(
      ReportsRequest(
        period: ReportPeriodOption(
          id: '${now.year}-${now.month}',
          label: 'Current month',
          timeframe: ReportTimeframe.month,
          start: periodStart,
          end: periodEnd,
          caption: 'Test',
          isCurrent: true,
        ),
        comparisonMode: ReportComparisonMode.none,
        allowanceMode: AllowanceMode.paycheck,
      ),
    );

    final targetPerDay = snapshot.allowance.dailyTargetForPeriod;
    final expectedBanked = targetPerDay * elapsedDays;
    final inflatedBanked = targetPerDay * totalDays;

    expect(snapshot.allowance.bankedBuilt, closeTo(expectedBanked, 0.01));
    expect(snapshot.allowance.bankedBuilt, lessThan(inflatedBanked * 0.9));
    expect(snapshot.habits.noSpendDays, elapsedDays);
  });
}
