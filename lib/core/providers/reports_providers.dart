import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/leko_database.dart';
import '../../domain/services/reports_service.dart';
import 'allowance_providers.dart';
import 'bills_providers.dart';
import 'closeout_providers.dart';
import 'goals_providers.dart';
import 'ledger_providers.dart';
import 'recurring_income_providers.dart';
import 'recovery_providers.dart';
import 'settings_providers.dart';

final reportsServiceProvider = Provider<ReportsService>((ref) {
  return ReportsService(
    ref.watch(transactionsRepositoryProvider),
    ref.watch(categoriesRepositoryProvider),
    ref.watch(billsRepositoryProvider),
    ref.watch(recurringIncomeRepositoryProvider),
    ref.watch(goalsRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
    ref.watch(allowanceEngineProvider),
    ref.watch(closeoutServiceProvider),
    ref.watch(recoveryPlansRepositoryProvider),
  );
});

final reportsTransactionsInvalidationProvider = StreamProvider((ref) {
  return ref.watch(transactionsRepositoryProvider).watchAll();
});

final reportPeriodOptionsProvider =
    FutureProvider.family<List<ReportPeriodOption>, ReportTimeframe>((
  ref,
  timeframe,
) async {
  ref.watch(settingsStreamProvider);
  ref.watch(recurringIncomesProvider);
  final service = ref.watch(reportsServiceProvider);
  return service.availablePeriods(timeframe);
});

final reportsSnapshotProvider =
    FutureProvider.family<ReportsSnapshot, ReportsRequest>((ref, request) async {
  ref.watch(reportsTransactionsInvalidationProvider);
  ref.watch(categoriesProvider);
  ref.watch(billsStreamProvider);
  ref.watch(goalsStreamProvider);
  ref.watch(recurringIncomesProvider);
  ref.watch(settingsStreamProvider);
  ref.watch(activeRecoveryPlanProvider);
  ref.watch(closeoutsStreamProvider);
  final service = ref.watch(reportsServiceProvider);
  return service.buildSnapshot(request);
});

final reportDrilldownTransactionsProvider =
    FutureProvider.family<List<Transaction>, ReportDrilldownQuery>((
  ref,
  query,
) async {
  ref.watch(reportsTransactionsInvalidationProvider);
  ref.watch(categoriesProvider);
  final service = ref.watch(reportsServiceProvider);
  return service.transactionsForDrilldown(query);
});

final reportBillRowsProvider =
    FutureProvider.family<List<ReportDrilldownRow>, ReportPeriodOption>((
  ref,
  period,
) async {
  ref.watch(reportsTransactionsInvalidationProvider);
  ref.watch(billsStreamProvider);
  final service = ref.watch(reportsServiceProvider);
  return service.billDrilldownRows(period);
});
