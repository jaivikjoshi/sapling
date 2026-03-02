import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/enums.dart';
import '../../domain/services/allowance_engine.dart';
import 'bills_providers.dart';
import 'goals_providers.dart';
import 'ledger_providers.dart';
import 'recurring_income_providers.dart';
import 'settings_providers.dart';

final allowanceEngineProvider = Provider<AllowanceEngine>((ref) {
  return AllowanceEngine(
    ref.watch(transactionsRepositoryProvider),
    ref.watch(billsRepositoryProvider),
    ref.watch(recurringIncomeRepositoryProvider),
    ref.watch(goalsRepositoryProvider),
  );
});

/// Runtime mode state — defaults to user's preferred mode from settings.
final allowanceModeOverrideProvider =
    StateProvider<AllowanceMode?>((ref) => null);

/// Effective mode: uses the override if set, otherwise the settings default.
final effectiveAllowanceModeProvider = Provider<AllowanceMode>((ref) {
  final override = ref.watch(allowanceModeOverrideProvider);
  if (override != null) return override;
  final settings = ref.watch(settingsStreamProvider).valueOrNull;
  return settings?.allowanceDefaultMode ?? AllowanceMode.paycheck;
});

final paycheckAllowanceProvider =
    FutureProvider<PaycheckAllowanceResult?>((ref) async {
  final settingsAsync = ref.watch(settingsStreamProvider);
  final settings = settingsAsync.valueOrNull;
  if (settings == null) return null;

  ref.watch(balanceStreamProvider);
  ref.watch(billsStreamProvider);
  ref.watch(recurringIncomesProvider);

  final engine = ref.watch(allowanceEngineProvider);
  return engine.computePaycheckMode(settings: settings);
});

final goalAllowanceProvider =
    FutureProvider<GoalAllowanceResult?>((ref) async {
  final settingsAsync = ref.watch(settingsStreamProvider);
  final settings = settingsAsync.valueOrNull;
  if (settings == null) return null;

  ref.watch(balanceStreamProvider);
  ref.watch(billsStreamProvider);
  ref.watch(recurringIncomesProvider);
  ref.watch(goalsStreamProvider);

  final engine = ref.watch(allowanceEngineProvider);
  return engine.computeGoalMode(settings: settings);
});
