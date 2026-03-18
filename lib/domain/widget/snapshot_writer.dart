import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../../core/utils/enum_serialization.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/repositories/goals_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../models/daily_snapshot.dart';
import '../models/enums.dart';
import '../models/settings_model.dart';
import '../services/allowance_engine.dart';
import '../services/closeout_service.dart';
import 'snapshot_builder.dart';

/// Writes DailySnapshot as JSON to App Group (iOS) / shared storage for the widget.
/// Call writeSnapshot() after meaningful events so the widget can render offline.
class SnapshotWriter {
  final SettingsRepository _settingsRepo;
  final AllowanceEngine _allowanceEngine;
  final CloseoutService _closeoutService;
  final GoalsRepository? _goalsRepo;

  static const String _dataKey = 'leko_daily_snapshot';

  SnapshotWriter(
    this._settingsRepo,
    this._allowanceEngine,
    this._closeoutService, [
    this._goalsRepo,
  ]);

  /// Build current snapshot from services and write to shared storage; then request widget refresh.
  Future<void> writeSnapshot() async {
    try {
      final settings = await _settingsRepo.get();
      final userSettings = UserSettings.fromDb(settings);
      final streak = await _closeoutService.computeStreak(settings: userSettings);

      final mode = enumFromDb<AllowanceMode>(
        settings.allowanceDefaultMode,
        AllowanceMode.values,
      );

      if (mode == AllowanceMode.goal &&
          settings.primaryGoalId != null &&
          _goalsRepo != null) {
        final result = await _allowanceEngine.computeGoalMode(settings: userSettings);
        if (result != null) {
          await _write(SnapshotBuilder.fromGoal(result, streak));
          return;
        }
      }

      final result = await _allowanceEngine.computePaycheckMode(settings: userSettings);
      if (result != null) {
        await _write(SnapshotBuilder.fromPaycheck(result, streak));
      }
    } catch (_) {}
  }

  Future<void> _write(DailySnapshot snapshot) async {
    final json = jsonEncode(snapshot.toJson());
    await HomeWidget.saveWidgetData<String>(_dataKey, json);
    await HomeWidget.updateWidget(
      iOSName: 'LekoWidget',
      androidName: 'LekoWidget',
    );
  }
}
