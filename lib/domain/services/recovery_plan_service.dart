import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/repositories/recovery_plans_repository.dart';
import '../models/enums.dart';

class RecoveryAdjustment {
  final DateTime date;
  final double adjustment;

  const RecoveryAdjustment({required this.date, required this.adjustment});
}

class RecoveryPlanService {
  final RecoveryPlansRepository _repo;
  static const _uuid = Uuid();

  RecoveryPlanService(this._repo);

  Stream<RecoveryPlan?> watchActive() => _repo.watchActive();
  Future<RecoveryPlan?> getActive() => _repo.getActive();

  /// PRD 5.13 Plan A: Reduce next N days.
  /// r = Over / N. For N day buckets, adjustment = -r.
  Future<String> createReduceNextNDays({
    required String triggerTransactionId,
    required double overspendAmount,
    int days = 7,
  }) async {
    await _repo.cancelAll();
    final id = _uuid.v4();
    final r = overspendAmount / days;
    final params = jsonEncode({'days': days, 'dailyReduction': r});

    await _repo.insert(RecoveryPlansCompanion.insert(
      id: id,
      createdAt: DateTime.now(),
      triggerTransactionId: triggerTransactionId,
      overspendAmount: overspendAmount,
      planType: enumToDb(RecoveryPlanType.reduceNextNDays),
      parameters: Value(params),
    ));
    return id;
  }

  /// PRD 5.13 Plan B: Reduce weekends only.
  Future<String> createReduceWeekendsOnly({
    required String triggerTransactionId,
    required double overspendAmount,
    int weekendDays = 4,
  }) async {
    await _repo.cancelAll();
    final id = _uuid.v4();
    final r = overspendAmount / weekendDays;
    final params = jsonEncode({
      'weekendDays': weekendDays,
      'weekendReduction': r,
    });

    await _repo.insert(RecoveryPlansCompanion.insert(
      id: id,
      createdAt: DateTime.now(),
      triggerTransactionId: triggerTransactionId,
      overspendAmount: overspendAmount,
      planType: enumToDb(RecoveryPlanType.reduceWeekendsOnly),
      parameters: Value(params),
    ));
    return id;
  }

  /// PRD 5.13 Plan C: Push goal date.
  Future<String> createPushGoalDate({
    required String triggerTransactionId,
    required double overspendAmount,
    int pushDays = 14,
  }) async {
    await _repo.cancelAll();
    final id = _uuid.v4();
    final params = jsonEncode({'pushDays': pushDays});

    await _repo.insert(RecoveryPlansCompanion.insert(
      id: id,
      createdAt: DateTime.now(),
      triggerTransactionId: triggerTransactionId,
      overspendAmount: overspendAmount,
      planType: enumToDb(RecoveryPlanType.pushGoalDate),
      parameters: Value(params),
    ));
    return id;
  }

  /// PRD 5.13 Plan D: Temp switch saving style for 1 cycle.
  Future<String> createTempSwitchStyle({
    required String triggerTransactionId,
    required double overspendAmount,
    required SavingStyle targetStyle,
  }) async {
    await _repo.cancelAll();
    final id = _uuid.v4();
    final params = jsonEncode({'targetStyle': enumToDb(targetStyle)});

    await _repo.insert(RecoveryPlansCompanion.insert(
      id: id,
      createdAt: DateTime.now(),
      triggerTransactionId: triggerTransactionId,
      overspendAmount: overspendAmount,
      planType: enumToDb(RecoveryPlanType.tempSwitchSavingStyle),
      parameters: Value(params),
    ));
    return id;
  }

  Future<void> cancel(String id) async {
    await _repo.updateById(
      id,
      const RecoveryPlansCompanion(status: Value('canceled')),
    );
  }

  Future<void> cancelAll() => _repo.cancelAll();

  /// Compute today's recovery adjustment (≤ 0) from the active plan.
  static double computeTodayAdjustment(RecoveryPlan? plan) {
    if (plan == null || plan.status != 'active') return 0;

    final type = enumFromDb<RecoveryPlanType>(
        plan.planType, RecoveryPlanType.values);
    final params = jsonDecode(plan.parameters) as Map<String, dynamic>;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planStart = DateTime(
        plan.createdAt.year, plan.createdAt.month, plan.createdAt.day);

    switch (type) {
      case RecoveryPlanType.reduceNextNDays:
        final days = (params['days'] as num).toInt();
        final r = (params['dailyReduction'] as num).toDouble();
        final daysSincePlan = today.difference(planStart).inDays;
        if (daysSincePlan < days) return -r;
        return 0;

      case RecoveryPlanType.reduceWeekendsOnly:
        final r = (params['weekendReduction'] as num).toDouble();
        final weekday = now.weekday;
        if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
          return -r;
        }
        return 0;

      case RecoveryPlanType.pushGoalDate:
        return 0;

      case RecoveryPlanType.tempSwitchSavingStyle:
        return 0;
    }
  }

  /// Build the full per-day schedule for display/verification.
  static List<RecoveryAdjustment> buildSchedule(RecoveryPlan plan) {
    final type = enumFromDb<RecoveryPlanType>(
        plan.planType, RecoveryPlanType.values);
    final params = jsonDecode(plan.parameters) as Map<String, dynamic>;
    final planStart = DateTime(
        plan.createdAt.year, plan.createdAt.month, plan.createdAt.day);
    final schedule = <RecoveryAdjustment>[];

    switch (type) {
      case RecoveryPlanType.reduceNextNDays:
        final days = (params['days'] as num).toInt();
        final r = (params['dailyReduction'] as num).toDouble();
        for (var i = 0; i < days; i++) {
          final day = DateTime(
              planStart.year, planStart.month, planStart.day + i);
          schedule.add(RecoveryAdjustment(date: day, adjustment: -r));
        }

      case RecoveryPlanType.reduceWeekendsOnly:
        final weekendDays = (params['weekendDays'] as num).toInt();
        final r = (params['weekendReduction'] as num).toDouble();
        var found = 0;
        var cursor = planStart;
        while (found < weekendDays) {
          if (cursor.weekday == DateTime.saturday ||
              cursor.weekday == DateTime.sunday) {
            schedule.add(RecoveryAdjustment(date: cursor, adjustment: -r));
            found++;
          }
          cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
        }

      case RecoveryPlanType.pushGoalDate:
        break;

      case RecoveryPlanType.tempSwitchSavingStyle:
        break;
    }

    return schedule;
  }
}
