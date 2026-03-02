import 'package:uuid/uuid.dart';

import '../../core/utils/enum_serialization.dart';
import '../../data/db/sapling_database.dart';
import '../../data/repositories/daily_closeouts_repository.dart';
import '../../domain/models/enums.dart';
import '../models/settings_model.dart';
import 'allowance_engine.dart' show AllowanceEngineForStreak;

/// Date bucket = local date at midnight (day-only).
/// Streak is computed from logged spending vs budget (not self-report).
class CloseoutService {
  final DailyCloseoutsRepository _repo;
  final AllowanceEngineForStreak _allowanceEngine;
  static const _uuid = Uuid();

  CloseoutService(this._repo, this._allowanceEngine);

  static DateTime dateBucket(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Record closeout (kept for compatibility; streak no longer uses this).
  Future<void> recordCloseout(DateTime date, CloseoutResult result) async {
    final bucket = dateBucket(date);
    final existing = await _repo.getByDateBucket(bucket);
    if (existing != null) await _repo.deleteById(existing.id);
    final now = DateTime.now();
    await _repo.insert(DailyCloseoutsCompanion.insert(
      id: _uuid.v4(),
      date: bucket,
      result: enumToDb(result),
      createdAt: now,
    ));
  }

  /// Streak = consecutive days (going back from reference date) where
  /// logged spending that day was within that day's budget.
  Future<StreakResult> computeStreak({
    required UserSettings settings,
    DateTime? referenceDate,
  }) async {
    final ref = referenceDate ?? DateTime.now();
    final bucket = dateBucket(ref);

    final todayWithinBudget = await _allowanceEngine.wasWithinBudgetOnDate(bucket, settings);

    int count = 0;
    for (int offset = 0; offset < 366; offset++) {
      final d = bucket.subtract(Duration(days: offset));
      final within = await _allowanceEngine.wasWithinBudgetOnDate(d, settings);
      if (!within) break;
      count++;
    }

    return StreakResult(
      currentStreak: count,
      todayWithinBudget: todayWithinBudget,
    );
  }

  Future<DailyCloseout?> getCloseoutForDate(DateTime date) {
    return _repo.getByDateBucket(dateBucket(date));
  }

  Stream<List<DailyCloseout>> watchAll() {
    return _repo.getAllOrderedByDateDesc().asStream();
  }
}

class StreakResult {
  final int currentStreak;
  final bool todayWithinBudget;

  const StreakResult({
    required this.currentStreak,
    required this.todayWithinBudget,
  });
}
