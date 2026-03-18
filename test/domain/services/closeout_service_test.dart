import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leko/data/db/leko_database.dart';
import 'package:leko/data/repositories/daily_closeouts_repository.dart';
import 'package:leko/domain/models/enums.dart';
import 'package:leko/domain/models/settings_model.dart';
import 'package:leko/domain/services/allowance_engine.dart';
import 'package:leko/domain/services/closeout_service.dart';

UserSettings get _testSettings => UserSettings.defaults;

/// Fake for testing streak; answers from a map keyed by date bucket (day-only).
class FakeAllowanceEngineForStreak extends AllowanceEngineForStreak {
  bool Function(DateTime date)? withinBudgetOverride;

  FakeAllowanceEngineForStreak({this.withinBudgetOverride});

  @override
  Future<bool> wasWithinBudgetOnDate(DateTime date, UserSettings settings) async {
    if (withinBudgetOverride != null) return withinBudgetOverride!(date);
    return true;
  }
}

void main() {
  late LekoDatabase db;
  late DailyCloseoutsRepository repo;
  late FakeAllowanceEngineForStreak fakeEngine;
  late CloseoutService service;

  setUp(() {
    db = LekoDatabase.forTesting(NativeDatabase.memory());
    repo = DriftDailyCloseoutsRepository(db);
    fakeEngine = FakeAllowanceEngineForStreak();
    service = CloseoutService(repo, fakeEngine);
  });

  tearDown(() => db.close());

  Future<void> _insert(DateTime date, String result) async {
    final now = DateTime.now();
    await db.into(db.dailyCloseouts).insert(DailyCloseoutsCompanion.insert(
      id: '${date.millisecondsSinceEpoch}',
      date: CloseoutService.dateBucket(date),
      result: result,
      createdAt: now,
    ));
  }

  group('dateBucket', () {
    test('strips time to midnight local', () {
      final d = DateTime(2025, 3, 15, 14, 30);
      final b = CloseoutService.dateBucket(d);
      expect(b.year, 2025);
      expect(b.month, 3);
      expect(b.day, 15);
      expect(b.hour, 0);
      expect(b.minute, 0);
    });
  });

  group('recordCloseout', () {
    test('stores closeout for date bucket', () async {
      final date = DateTime(2025, 4, 10);
      await service.recordCloseout(date, CloseoutResult.noSpend);
      final c = await service.getCloseoutForDate(date);
      expect(c != null, true);
      expect(c!.result, 'no_spend');
    });

    test('replaces existing closeout for same day', () async {
      final date = DateTime(2025, 4, 10);
      await service.recordCloseout(date, CloseoutResult.noSpend);
      await service.recordCloseout(date, CloseoutResult.addedExpense);
      final c = await service.getCloseoutForDate(date);
      expect(c!.result, 'added_expense');
    });
  });

  group('computeStreak (budget-based)', () {
    test('empty / all-over returns zero streak', () async {
      fakeEngine.withinBudgetOverride = (_) => false;
      final s = await service.computeStreak(
        settings: _testSettings,
        referenceDate: DateTime(2025, 4, 15),
      );
      expect(s.currentStreak, 0);
      expect(s.todayWithinBudget, false);
    });

    test('consecutive within-budget days count as streak', () async {
      final ref = DateTime(2025, 4, 15);
      fakeEngine.withinBudgetOverride = (d) {
        final b = DateTime(d.year, d.month, d.day);
        if (b.isBefore(DateTime(2025, 4, 12)) || b.isAfter(ref)) return false;
        return true; // 12, 13, 14, 15 within budget
      };
      final s = await service.computeStreak(
        settings: _testSettings,
        referenceDate: ref,
      );
      expect(s.currentStreak, 4);
      expect(s.todayWithinBudget, true);
    });

    test('streak stops at first over-budget day going backward', () async {
      final ref = DateTime(2025, 4, 15);
      fakeEngine.withinBudgetOverride = (d) {
        final b = DateTime(d.year, d.month, d.day);
        if (b == DateTime(2025, 4, 13)) return false;
        return b.isAfter(DateTime(2025, 4, 9)) && !b.isAfter(ref);
      };
      final s = await service.computeStreak(
        settings: _testSettings,
        referenceDate: ref,
      );
      expect(s.currentStreak, 2); // 15, 14 then 13 breaks
      expect(s.todayWithinBudget, true);
    });

    test('todayWithinBudget reflects reference day', () async {
      final ref = DateTime(2025, 4, 15);
      fakeEngine.withinBudgetOverride = (d) {
        final b = DateTime(d.year, d.month, d.day);
        return b == ref;
      };
      final s = await service.computeStreak(
        settings: _testSettings,
        referenceDate: ref,
      );
      expect(s.currentStreak, 1);
      expect(s.todayWithinBudget, true);
    });

    test('todayWithinBudget false when reference day over', () async {
      final ref = DateTime(2025, 4, 15);
      fakeEngine.withinBudgetOverride = (d) {
        final b = DateTime(d.year, d.month, d.day);
        return b.isBefore(ref) && b.isAfter(DateTime(2025, 4, 12));
      };
      final s = await service.computeStreak(
        settings: _testSettings,
        referenceDate: ref,
      );
      expect(s.currentStreak, 0);
      expect(s.todayWithinBudget, false);
    });
  });
}
