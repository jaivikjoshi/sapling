import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/leko_database.dart';
import '../repositories/settings_repository.dart';
import '../supabase/entity_mappers.dart';

/// Supabase-backed settings repository. Ensures app_settings row exists on first access.
class SupabaseSettingsRepository implements SettingsRepository {
  SupabaseSettingsRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const _pollInterval = Duration(seconds: 30);

  /// Single-flight: prevents concurrent _ensureAndGet from racing on insert.
  Future<AppSetting>? _ensureFuture;

  AppSetting _defaultSettings() {
    return const AppSetting(
      id: 'singleton',
      baseCurrency: 'cad',
      rolloverResetType: 'monthly',
      spendingBaselineDays: 30,
      allowanceDefaultMode: 'paycheck',
      primaryGoalId: null,
      paydayAnchorRecurringIncomeId: null,
      defaultPaydayBehavior: 'confirm_actual_on_payday',
      paydayEnabled: true,
      billsEnabled: true,
      overspendEnabled: true,
      cycleResetEnabled: false,
      nightlyCloseoutEnabled: true,
      nightlyCloseoutTime: '21:00',
      onboardingCompleted: false,
    );
  }

  /// Ensures app_settings row exists for user; creates with defaults if not.
  /// Single-flight: concurrent callers share the same request to avoid duplicate-insert races.
  Future<AppSetting> _ensureAndGet() async {
    if (_client.auth.currentUser?.id != _userId) {
      return _defaultSettings();
    }
    if (_ensureFuture != null) return _ensureFuture!;
    _ensureFuture = _ensureAndGetImpl();
    try {
      return await _ensureFuture!;
    } finally {
      _ensureFuture = null;
    }
  }

  Future<AppSetting> _ensureAndGetImpl() async {
    final res = await _client
        .from('app_settings')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();
    if (res != null) {
      return appSettingFromSupabase(res);
    }
    final now = DateTime.now();
    final defaults = _defaultSettings();
    final map = appSettingToSupabase(defaults);
    map['user_id'] = _userId;
    map['created_at'] = now.toIso8601String();
    map['updated_at'] = now.toIso8601String();
    map.remove('id');
    try {
      await _client.from('app_settings').upsert(
        map,
        onConflict: 'user_id',
        ignoreDuplicates: true,
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final retry = await _client
            .from('app_settings')
            .select()
            .eq('user_id', _userId)
            .maybeSingle();
        if (retry != null) return appSettingFromSupabase(retry);
        rethrow;
      }
      rethrow;
    }
    return defaults;
  }

  @override
  Future<AppSetting> get() async => _ensureAndGet();

  @override
  Stream<AppSetting> watch() async* {
    try {
      yield await _ensureAndGet();
      await for (final _ in Stream.periodic(_pollInterval)) {
        if (_client.auth.currentUser?.id != _userId) {
          break;
        }
        yield await _ensureAndGet();
      }
    } on PostgrestException catch (e) {
      if (e.code != '42501') rethrow;
    }
  }

  @override
  Future<void> update(AppSettingsCompanion companion) async {
    final updateMap = <String, dynamic>{};
    if (companion.baseCurrency.present) {
      updateMap['base_currency'] = companion.baseCurrency.value;
    }
    if (companion.rolloverResetType.present) {
      updateMap['rollover_reset_type'] = companion.rolloverResetType.value;
    }
    if (companion.spendingBaselineDays.present) {
      updateMap['spending_baseline_days'] = companion.spendingBaselineDays.value;
    }
    if (companion.allowanceDefaultMode.present) {
      updateMap['allowance_default_mode'] = companion.allowanceDefaultMode.value;
    }
    if (companion.primaryGoalId.present) {
      updateMap['primary_goal_id'] = companion.primaryGoalId.value;
    }
    if (companion.paydayAnchorRecurringIncomeId.present) {
      updateMap['payday_anchor_recurring_income_id'] =
          companion.paydayAnchorRecurringIncomeId.value;
    }
    if (companion.defaultPaydayBehavior.present) {
      updateMap['default_payday_behavior'] =
          companion.defaultPaydayBehavior.value;
    }
    if (companion.paydayEnabled.present) {
      updateMap['payday_enabled'] = companion.paydayEnabled.value;
    }
    if (companion.billsEnabled.present) {
      updateMap['bills_enabled'] = companion.billsEnabled.value;
    }
    if (companion.overspendEnabled.present) {
      updateMap['overspend_enabled'] = companion.overspendEnabled.value;
    }
    if (companion.cycleResetEnabled.present) {
      updateMap['cycle_reset_enabled'] = companion.cycleResetEnabled.value;
    }
    if (companion.nightlyCloseoutEnabled.present) {
      updateMap['nightly_closeout_enabled'] =
          companion.nightlyCloseoutEnabled.value;
    }
    if (companion.nightlyCloseoutTime.present) {
      updateMap['nightly_closeout_time'] = companion.nightlyCloseoutTime.value;
    }
    if (companion.onboardingCompleted.present) {
      updateMap['onboarding_completed'] = companion.onboardingCompleted.value;
    }
    if (updateMap.isEmpty) return;
    updateMap['updated_at'] = DateTime.now().toIso8601String();
    await _client
        .from('app_settings')
        .update(updateMap)
        .eq('user_id', _userId);
  }

  @override
  Future<void> markOnboardingComplete() async {
    await update(
      const AppSettingsCompanion(onboardingCompleted: Value(true)),
    );
  }
}
