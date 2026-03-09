import 'dart:math' as math;

import '../models/plant_state.dart';
import '../models/settings_model.dart';
import 'allowance_engine.dart' show AllowanceEngineForStreak;
import 'closeout_service.dart';

/// Pure business logic for the plant growth system.
/// No UI dependency. Fully testable.
class PlantService {
  final AllowanceEngineForStreak _allowanceEngine;
  final CloseoutService _closeoutService;

  PlantService(this._allowanceEngine, this._closeoutService);

  static DateTime _dateBucket(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Evaluate the plant for all days since the last evaluation up to today.
  /// Returns the updated [PlantState]. Idempotent — safe to call multiple times.
  Future<PlantState> updatePlant({
    required PlantState current,
    required UserSettings settings,
    DateTime? now,
  }) async {
    final today = _dateBucket(now ?? DateTime.now());
    final lastEval = current.lastEvaluatedDate;

    // Already evaluated today — no-op.
    if (!lastEval.isBefore(today)) return current;

    // Fetch the current streak to update longestStreak and currentStreak.
    final streakResult = await _closeoutService.computeStreak(settings: settings);

    var state = current;

    // Walk each day from (lastEval + 1) through today.
    var date = lastEval.add(const Duration(days: 1));
    while (!date.isAfter(today)) {
      final withinBudget =
          await _allowanceEngine.wasWithinBudgetOnDate(date, settings);
      state = evaluateDay(state, withinBudget);
      date = date.add(const Duration(days: 1));
    }

    // Sync streak values from the live computation.
    final newLongest = math.max(state.longestStreak, streakResult.currentStreak);

    return state.copyWith(
      currentStreak: streakResult.currentStreak,
      longestStreak: newLongest,
      lastEvaluatedDate: today,
    );
  }

  /// Pure, synchronous single-day evaluation. No side effects.
  PlantState evaluateDay(PlantState state, bool withinBudget) {
    if (withinBudget) {
      final newStreak = state.currentStreak + 1;
      int bonusGrowth = 0;
      // Milestone bonuses
      if (newStreak == 7) bonusGrowth = 3;
      if (newStreak == 14) bonusGrowth = 5;
      if (newStreak == 30) bonusGrowth = 10;

      return state.copyWith(
        growthPoints: state.growthPoints + 1 + bonusGrowth,
        healthScore: math.min(100, state.healthScore + 15),
        currentStreak: newStreak,
        longestStreak: math.max(state.longestStreak, newStreak),
        daysAtZero: 0,
      );
    } else {
      final newDaysAtZero = state.daysAtZero + 1;
      // Health decay: -12 per day at zero
      final newHealth = math.max(0, state.healthScore - 12);
      // Prolonged neglect: after 7 days at zero, start losing growth points
      final growthLoss = newDaysAtZero >= 7 ? 1 : 0;
      return state.copyWith(
        healthScore: newHealth,
        currentStreak: 0,
        daysAtZero: newDaysAtZero,
        growthPoints: math.max(0, state.growthPoints - growthLoss),
      );
    }
  }
}
