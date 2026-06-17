import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/enums.dart';
import '../../domain/services/finance_summary_service.dart';
import 'allowance_providers.dart';
import 'bills_providers.dart';
import 'goals_providers.dart';
import 'ledger_providers.dart';
import 'recurring_income_providers.dart';
import 'settings_providers.dart';

final financeSummaryServiceProvider = Provider<FinanceSummaryService>((ref) {
  return FinanceSummaryService(
    allowanceEngine: ref.watch(allowanceEngineProvider),
    transactionsRepository: ref.watch(transactionsRepositoryProvider),
  );
});

final financeSummaryProvider = FutureProvider<FinanceSummary?>((ref) async {
  final settings = ref.watch(settingsStreamProvider).valueOrNull;
  if (settings == null) return null;

  ref.watch(balanceStreamProvider);
  ref.watch(billsStreamProvider);
  ref.watch(recurringIncomesProvider);
  ref.watch(goalsStreamProvider);

  final mode = ref.watch(effectiveAllowanceModeProvider);
  return ref
      .watch(financeSummaryServiceProvider)
      .compute(settings: settings, modeOverride: mode);
});

final productionActivationMilestoneProvider = Provider<bool>((ref) {
  final summary = ref.watch(financeSummaryProvider).valueOrNull;
  if (summary == null) return false;
  return summary.balance.abs() > 0.005 ||
      summary.incomeThisCycle > 0.005 ||
      summary.expensesThisCycle > 0.005 ||
      summary.mode == AllowanceMode.goal;
});
