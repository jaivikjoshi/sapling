import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/data/db/sapling_database.dart';
import 'package:sapling/data/repositories/recovery_plans_repository.dart';
import 'package:sapling/domain/services/recovery_plan_service.dart';

void main() {
  late SaplingDatabase db;
  late RecoveryPlansRepository repo;
  late RecoveryPlanService service;

  setUp(() {
    db = SaplingDatabase.forTesting(NativeDatabase.memory());
    repo = DriftRecoveryPlansRepository(db);
    service = RecoveryPlanService(repo);
  });

  tearDown(() => db.close());

  group('RecoveryPlanService — create plans', () {
    test('createReduceNextNDays creates active plan with correct params',
        () async {
      final id = await service.createReduceNextNDays(
        triggerTransactionId: 'txn-1',
        overspendAmount: 70,
        days: 7,
      );

      final plan = await repo.getActive();
      expect(plan, isNot(equals(null)));
      expect(plan!.id, id);
      expect(plan.status, 'active');
      expect(plan.overspendAmount, 70);

      final params = jsonDecode(plan.parameters) as Map<String, dynamic>;
      expect(params['days'], 7);
      expect(params['dailyReduction'], 10.0);
    });

    test('createReduceWeekendsOnly stores correct params', () async {
      await service.createReduceWeekendsOnly(
        triggerTransactionId: 'txn-2',
        overspendAmount: 100,
        weekendDays: 4,
      );

      final plan = await repo.getActive();
      expect(plan, isNot(equals(null)));

      final params = jsonDecode(plan!.parameters) as Map<String, dynamic>;
      expect(params['weekendDays'], 4);
      expect(params['weekendReduction'], 25.0);
    });

    test('creating a new plan cancels the previous one', () async {
      await service.createReduceNextNDays(
        triggerTransactionId: 'txn-1',
        overspendAmount: 50,
        days: 7,
      );

      final id2 = await service.createReduceWeekendsOnly(
        triggerTransactionId: 'txn-2',
        overspendAmount: 80,
        weekendDays: 4,
      );

      final all = await repo.getAll();
      final active = all.where((p) => p.status == 'active').toList();
      expect(active.length, 1);
      expect(active.first.id, id2);

      final canceled = all.where((p) => p.status == 'canceled').toList();
      expect(canceled.length, 1);
    });
  });

  group('RecoveryPlanService — cancel', () {
    test('cancel sets plan status to canceled', () async {
      final id = await service.createReduceNextNDays(
        triggerTransactionId: 'txn-1',
        overspendAmount: 50,
        days: 7,
      );

      await service.cancel(id);
      final plan = await repo.getActive();
      expect(plan, equals(null));
    });

    test('cancelAll cancels all active plans', () async {
      await service.createReduceNextNDays(
        triggerTransactionId: 'txn-1',
        overspendAmount: 50,
        days: 7,
      );

      await service.cancelAll();
      final plan = await repo.getActive();
      expect(plan, equals(null));
    });
  });

  group('RecoveryPlanService — computeTodayAdjustment', () {
    test('returns 0 when no active plan', () {
      expect(RecoveryPlanService.computeTodayAdjustment(null), 0);
    });

    test('reduceNextNDays returns negative daily amount within window',
        () async {
      await service.createReduceNextNDays(
        triggerTransactionId: 'txn-1',
        overspendAmount: 70,
        days: 7,
      );

      final plan = await repo.getActive();
      final adj = RecoveryPlanService.computeTodayAdjustment(plan);
      expect(adj, -10.0);
    });

    test('reduceWeekendsOnly returns 0 on weekday', () async {
      await service.createReduceWeekendsOnly(
        triggerTransactionId: 'txn-1',
        overspendAmount: 100,
        weekendDays: 4,
      );

      final plan = await repo.getActive();
      final adj = RecoveryPlanService.computeTodayAdjustment(plan);
      final now = DateTime.now();
      if (now.weekday == DateTime.saturday ||
          now.weekday == DateTime.sunday) {
        expect(adj, -25.0);
      } else {
        expect(adj, 0);
      }
    });
  });

  group('RecoveryPlanService — buildSchedule', () {
    test('reduceNextNDays builds N-day schedule', () async {
      await service.createReduceNextNDays(
        triggerTransactionId: 'txn-1',
        overspendAmount: 70,
        days: 7,
      );

      final plan = await repo.getActive();
      final schedule = RecoveryPlanService.buildSchedule(plan!);
      expect(schedule.length, 7);

      for (final adj in schedule) {
        expect(adj.adjustment, -10.0);
      }
    });

    test('reduceWeekendsOnly builds weekend-only schedule', () async {
      await service.createReduceWeekendsOnly(
        triggerTransactionId: 'txn-1',
        overspendAmount: 100,
        weekendDays: 4,
      );

      final plan = await repo.getActive();
      final schedule = RecoveryPlanService.buildSchedule(plan!);
      expect(schedule.length, 4);

      for (final adj in schedule) {
        expect(adj.adjustment, -25.0);
        final wd = adj.date.weekday;
        expect(
          wd == DateTime.saturday || wd == DateTime.sunday,
          true,
          reason: 'Day ${adj.date} should be a weekend day',
        );
      }
    });

    test('all adjustments are non-positive', () async {
      await service.createReduceNextNDays(
        triggerTransactionId: 'txn-1',
        overspendAmount: 140,
        days: 14,
      );

      final plan = await repo.getActive();
      final schedule = RecoveryPlanService.buildSchedule(plan!);
      for (final adj in schedule) {
        expect(adj.adjustment, lessThanOrEqualTo(0));
      }
    });

    test('schedule sum equals -overspendAmount for reduceNextNDays',
        () async {
      await service.createReduceNextNDays(
        triggerTransactionId: 'txn-1',
        overspendAmount: 100,
        days: 10,
      );

      final plan = await repo.getActive();
      final schedule = RecoveryPlanService.buildSchedule(plan!);
      final total =
          schedule.fold<double>(0, (sum, adj) => sum + adj.adjustment);
      expect(total, closeTo(-100, 0.01));
    });
  });
}
