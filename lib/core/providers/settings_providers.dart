import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories_supabase/supabase_settings_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/settings_model.dart';
import 'auth_providers.dart';
import 'db_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return DriftSettingsRepository(ref.watch(databaseProvider));
  }
  return SupabaseSettingsRepository(ref.watch(supabaseClientProvider), userId);
});

final settingsStreamProvider = StreamProvider<UserSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watch().map(UserSettings.fromDb);
});

Future<void> saveSettingsField(
  SettingsRepository repo, {
  Currency? baseCurrency,
  RolloverResetType? rolloverResetType,
  int? spendingBaselineDays,
  AllowanceMode? allowanceDefaultMode,
  String? Function()? primaryGoalId,
  PaydayBehavior? defaultPaydayBehavior,
  String? Function()? paydayAnchorRecurringIncomeId,
  bool? paydayEnabled,
  bool? billsEnabled,
  bool? overspendEnabled,
  bool? cycleResetEnabled,
  bool? nightlyCloseoutEnabled,
  String? nightlyCloseoutTime,
}) async {
  final companion = AppSettingsCompanion(
    baseCurrency: baseCurrency != null
        ? Value(enumToDb(baseCurrency))
        : const Value.absent(),
    rolloverResetType: rolloverResetType != null
        ? Value(enumToDb(rolloverResetType))
        : const Value.absent(),
    spendingBaselineDays: spendingBaselineDays != null
        ? Value(spendingBaselineDays)
        : const Value.absent(),
    allowanceDefaultMode: allowanceDefaultMode != null
        ? Value(enumToDb(allowanceDefaultMode))
        : const Value.absent(),
    primaryGoalId: primaryGoalId != null
        ? Value(primaryGoalId())
        : const Value.absent(),
    defaultPaydayBehavior: defaultPaydayBehavior != null
        ? Value(enumToDb(defaultPaydayBehavior))
        : const Value.absent(),
    paydayAnchorRecurringIncomeId: paydayAnchorRecurringIncomeId != null
        ? Value(paydayAnchorRecurringIncomeId())
        : const Value.absent(),
    paydayEnabled:
        paydayEnabled != null ? Value(paydayEnabled) : const Value.absent(),
    billsEnabled:
        billsEnabled != null ? Value(billsEnabled) : const Value.absent(),
    overspendEnabled: overspendEnabled != null
        ? Value(overspendEnabled)
        : const Value.absent(),
    cycleResetEnabled: cycleResetEnabled != null
        ? Value(cycleResetEnabled)
        : const Value.absent(),
    nightlyCloseoutEnabled: nightlyCloseoutEnabled != null
        ? Value(nightlyCloseoutEnabled)
        : const Value.absent(),
    nightlyCloseoutTime: nightlyCloseoutTime != null
        ? Value(nightlyCloseoutTime)
        : const Value.absent(),
  );
  await repo.update(companion);
}
