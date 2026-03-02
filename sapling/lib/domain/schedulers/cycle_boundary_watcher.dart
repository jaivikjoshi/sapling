import '../../core/utils/enum_serialization.dart';
import '../../data/repositories/recurring_income_repository.dart';
import '../../data/repositories/scheduler_metadata_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../models/enums.dart';
import '../services/cycle_window_calculator.dart';

/// Detects cycle boundary crossing (e.g. new payday cycle) and updates metadata.
/// Optionally notifies when cycleResetEnabled. Banked allowance is recomputed
/// on next allowance read (no stored state to clear).
class CycleBoundaryWatcher {
  final SchedulerMetadataRepository _metadata;
  final SettingsRepository _settingsRepo;
  final RecurringIncomeRepository _incomeRepo;

  static const _keyLastCycleStart = 'lastCycleStart';

  CycleBoundaryWatcher(
    this._metadata,
    this._settingsRepo,
    this._incomeRepo,
  );

  /// Run on app launch / scheduler run. Returns true if boundary was crossed.
  Future<bool> checkAndUpdate(DateTime now) async {
    final settings = await _settingsRepo.get();
    final resetType = enumFromDb<RolloverResetType>(
      settings.rolloverResetType,
      RolloverResetType.values,
    );
    String? anchorFreq;
    DateTime? anchorNext;
    if (resetType == RolloverResetType.paydayBased) {
      final anchor = await _incomeRepo.getAnchor();
      if (anchor != null) {
        anchorFreq = anchor.frequency;
        anchorNext = anchor.nextPaydayDate;
      }
    }
    final window = CycleWindowCalculator.compute(
      resetType: resetType,
      now: now,
      anchorFrequency: anchorFreq,
      anchorNextPaydayDate: anchorNext,
    );
    final currentStart = _dayKey(window.start);
    final last = await _metadata.get(_keyLastCycleStart);
    await _metadata.set(_keyLastCycleStart, currentStart);
    return last != null && last != currentStart;
  }

  static String _dayKey(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
