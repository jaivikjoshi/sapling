import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/core/utils/date_helpers.dart';
import 'package:sapling/data/db/sapling_database.dart';
import 'package:sapling/data/repositories/recurring_income_repository.dart';
import 'package:sapling/domain/models/enums.dart';
import 'package:sapling/domain/services/recurring_income_service.dart';

void main() {
  late SaplingDatabase db;
  late RecurringIncomeRepository repo;
  late RecurringIncomeService service;

  setUp(() {
    db = SaplingDatabase.forTesting(NativeDatabase.memory());
    repo = RecurringIncomeRepository(db);
    service = RecurringIncomeService(repo);
  });

  tearDown(() => db.close());

  group('validateAutoPost', () {
    test('returns error when auto-post with null amount', () {
      final err = RecurringIncomeService.validateAutoPost(
        behavior: PaydayBehavior.autoPostExpected,
        expectedAmount: null,
      );
      expect(err, isNotNull);
    });

    test('returns error when auto-post with 0 amount', () {
      final err = RecurringIncomeService.validateAutoPost(
        behavior: PaydayBehavior.autoPostExpected,
        expectedAmount: 0,
      );
      expect(err, isNotNull);
    });

    test('passes when auto-post with positive amount', () {
      final err = RecurringIncomeService.validateAutoPost(
        behavior: PaydayBehavior.autoPostExpected,
        expectedAmount: 1500,
      );
      expect(err, isNull);
    });

    test('passes when confirm-actual regardless of amount', () {
      final err = RecurringIncomeService.validateAutoPost(
        behavior: PaydayBehavior.confirmActualOnPayday,
        expectedAmount: null,
      );
      expect(err, isNull);
    });
  });

  group('computeNextPayday (pure)', () {
    test('weekly advances by 7 days', () {
      final d = DateTime(2025, 3, 1);
      final next = RecurringIncomeService.computeNextPayday(
          d, IncomeFrequency.weekly);
      expect(next, DateTime(2025, 3, 8));
    });

    test('biweekly advances by 14 days', () {
      final d = DateTime(2025, 3, 1);
      final next = RecurringIncomeService.computeNextPayday(
          d, IncomeFrequency.biweekly);
      expect(next, DateTime(2025, 3, 15));
    });

    test('monthly advances to same day next month', () {
      final d = DateTime(2025, 1, 15);
      final next = RecurringIncomeService.computeNextPayday(
          d, IncomeFrequency.monthly);
      expect(next, DateTime(2025, 2, 15));
    });

    test('monthly handles month-end clamping (Jan 31 -> Feb 28)', () {
      final d = DateTime(2025, 1, 31);
      final next = RecurringIncomeService.computeNextPayday(
          d, IncomeFrequency.monthly);
      expect(next, DateTime(2025, 2, 28));
    });

    test('monthly handles December to January year wrap', () {
      final d = DateTime(2025, 12, 15);
      final next = RecurringIncomeService.computeNextPayday(
          d, IncomeFrequency.monthly);
      expect(next, DateTime(2026, 1, 15));
    });
  });

  group('advanceByIncomeFrequency (date_helpers)', () {
    test('leap year Feb 29 -> Mar 29 for monthly', () {
      final d = DateTime(2024, 2, 29);
      final next = advanceByIncomeFrequency(d, IncomeFrequency.monthly);
      expect(next, DateTime(2024, 3, 29));
    });
  });

  group('anchor exclusivity (DB)', () {
    test('only one anchor at a time', () async {
      await service.create(
        name: 'Job A',
        frequency: IncomeFrequency.biweekly,
        nextPaydayDate: DateTime(2025, 4, 1),
        paydayBehavior: PaydayBehavior.confirmActualOnPayday,
        isPaydayAnchor: true,
      );

      final id2 = await service.create(
        name: 'Job B',
        frequency: IncomeFrequency.monthly,
        nextPaydayDate: DateTime(2025, 4, 15),
        paydayBehavior: PaydayBehavior.confirmActualOnPayday,
        isPaydayAnchor: true,
      );

      final all = await repo.getAll();
      final anchors = all.where((i) => i.isPaydayAnchor).toList();
      expect(anchors.length, 1);
      expect(anchors.first.id, id2);
    });

    test('setPaydayAnchor switches from old to new', () async {
      final id1 = await service.create(
        name: 'Job A',
        frequency: IncomeFrequency.biweekly,
        nextPaydayDate: DateTime(2025, 4, 1),
        paydayBehavior: PaydayBehavior.confirmActualOnPayday,
        isPaydayAnchor: true,
      );

      final id2 = await service.create(
        name: 'Job B',
        frequency: IncomeFrequency.monthly,
        nextPaydayDate: DateTime(2025, 4, 15),
        paydayBehavior: PaydayBehavior.confirmActualOnPayday,
      );

      await service.setPaydayAnchor(id2);

      final all = await repo.getAll();
      final a = all.firstWhere((i) => i.id == id1);
      final b = all.firstWhere((i) => i.id == id2);
      expect(a.isPaydayAnchor, false);
      expect(b.isPaydayAnchor, true);
    });

    test('clearPaydayAnchor removes all anchors', () async {
      await service.create(
        name: 'Job A',
        frequency: IncomeFrequency.biweekly,
        nextPaydayDate: DateTime(2025, 4, 1),
        paydayBehavior: PaydayBehavior.confirmActualOnPayday,
        isPaydayAnchor: true,
      );

      await service.clearPaydayAnchor();

      final all = await repo.getAll();
      expect(all.every((i) => !i.isPaydayAnchor), true);
    });
  });

  group('advancePayday (DB)', () {
    test('advances nextPaydayDate by frequency', () async {
      final id = await service.create(
        name: 'Salary',
        frequency: IncomeFrequency.biweekly,
        nextPaydayDate: DateTime(2025, 3, 1),
        paydayBehavior: PaydayBehavior.confirmActualOnPayday,
      );

      await service.advancePayday(id);

      final updated = await repo.getById(id);
      expect(updated.nextPaydayDate, DateTime(2025, 3, 15));
    });

    test('advances monthly schedule correctly', () async {
      final id = await service.create(
        name: 'Salary',
        frequency: IncomeFrequency.monthly,
        nextPaydayDate: DateTime(2025, 1, 31),
        paydayBehavior: PaydayBehavior.confirmActualOnPayday,
      );

      await service.advancePayday(id);

      final updated = await repo.getById(id);
      expect(updated.nextPaydayDate, DateTime(2025, 2, 28));
    });
  });

  group('CRUD', () {
    test('create and getById returns correct data', () async {
      final id = await service.create(
        name: 'Freelance',
        frequency: IncomeFrequency.weekly,
        nextPaydayDate: DateTime(2025, 5, 1),
        expectedAmount: 500.0,
        paydayBehavior: PaydayBehavior.autoPostExpected,
      );

      final income = await service.getById(id);
      expect(income.name, 'Freelance');
      expect(income.expectedAmount, 500.0);
    });

    test('update modifies fields', () async {
      final id = await service.create(
        name: 'Old Name',
        frequency: IncomeFrequency.monthly,
        nextPaydayDate: DateTime(2025, 6, 1),
        paydayBehavior: PaydayBehavior.confirmActualOnPayday,
      );

      await service.update(
        id: id,
        name: 'New Name',
        frequency: IncomeFrequency.biweekly,
        nextPaydayDate: DateTime(2025, 6, 15),
        expectedAmount: 2000,
        paydayBehavior: PaydayBehavior.autoPostExpected,
      );

      final updated = await service.getById(id);
      expect(updated.name, 'New Name');
      expect(updated.expectedAmount, 2000);
    });

    test('delete removes the record', () async {
      final id = await service.create(
        name: 'Temp',
        frequency: IncomeFrequency.weekly,
        nextPaydayDate: DateTime(2025, 7, 1),
        paydayBehavior: PaydayBehavior.confirmActualOnPayday,
      );

      await service.delete(id);
      final all = await repo.getAll();
      expect(all.where((i) => i.id == id).isEmpty, true);
    });
  });
}
