import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leko/data/db/leko_database.dart';
import 'package:leko/data/repositories/categories_repository.dart';
import 'package:leko/data/repositories/transactions_repository.dart';
import 'package:leko/domain/services/reports_service.dart';

void main() {
  late LekoDatabase db;
  late TransactionsRepository txnRepo;
  late CategoriesRepository categoriesRepo;
  late ReportsService service;

  setUp(() async {
    db = LekoDatabase.forTesting(NativeDatabase.memory());
    txnRepo = DriftTransactionsRepository(db);
    categoriesRepo = DriftCategoriesRepository(db);
    service = ReportsService(txnRepo, categoriesRepo);
  });

  tearDown(() => db.close());

  Future<void> _insert(TransactionsCompanion c) => db.into(db.transactions).insert(c);

  group('monthlySummary', () {
    test('aggregates income expense adjustment correctly', () async {
      final now = DateTime.now();
      await _insert(TransactionsCompanion.insert(
        id: 't1',
        type: 'income',
        amount: 2000,
        date: DateTime(2025, 3, 15),
        createdAt: now,
        updatedAt: now,
      ));
      await _insert(TransactionsCompanion.insert(
        id: 't2',
        type: 'expense',
        amount: 300,
        date: DateTime(2025, 3, 10),
        categoryId: Value('cat_groceries'),
        createdAt: now,
        updatedAt: now,
      ));
      await _insert(TransactionsCompanion.insert(
        id: 't3',
        type: 'expense',
        amount: 100,
        date: DateTime(2025, 3, 20),
        categoryId: Value('cat_dining'),
        createdAt: now,
        updatedAt: now,
      ));
      await _insert(TransactionsCompanion.insert(
        id: 't4',
        type: 'adjustment',
        amount: 50,
        date: DateTime(2025, 3, 25),
        createdAt: now,
        updatedAt: now,
      ));

      final s = await service.monthlySummary(2025, 3);
      expect(s.incomeTotal, 2000);
      expect(s.expenseTotal, 400);
      expect(s.adjustmentTotal, 50);
      expect(s.net, 2000 - 400 + 50); // 1650
    });

    test('only includes transactions in month (date bucketing)', () async {
      final now = DateTime.now();
      await _insert(TransactionsCompanion.insert(
        id: 'feb',
        type: 'income',
        amount: 500,
        date: DateTime(2025, 2, 28),
        createdAt: now,
        updatedAt: now,
      ));
      await _insert(TransactionsCompanion.insert(
        id: 'mar',
        type: 'income',
        amount: 1000,
        date: DateTime(2025, 3, 1),
        createdAt: now,
        updatedAt: now,
      ));
      await _insert(TransactionsCompanion.insert(
        id: 'apr',
        type: 'income',
        amount: 2000,
        date: DateTime(2025, 4, 1),
        createdAt: now,
        updatedAt: now,
      ));

      final mar = await service.monthlySummary(2025, 3);
      expect(mar.incomeTotal, 1000);
    });

    test('empty month returns zeros', () async {
      final s = await service.monthlySummary(2026, 1);
      expect(s.incomeTotal, 0);
      expect(s.expenseTotal, 0);
      expect(s.adjustmentTotal, 0);
      expect(s.net, 0);
    });
  });

  group('annualSummary', () {
    test('aggregates full year', () async {
      final now = DateTime.now();
      await _insert(TransactionsCompanion.insert(
        id: 'y1',
        type: 'income',
        amount: 10000,
        date: DateTime(2025, 1, 1),
        createdAt: now,
        updatedAt: now,
      ));
      await _insert(TransactionsCompanion.insert(
        id: 'y2',
        type: 'expense',
        amount: 3000,
        date: DateTime(2025, 6, 15),
        categoryId: Value('cat_rent'),
        createdAt: now,
        updatedAt: now,
      ));
      await _insert(TransactionsCompanion.insert(
        id: 'y3',
        type: 'adjustment',
        amount: -100,
        date: DateTime(2025, 12, 31),
        createdAt: now,
        updatedAt: now,
      ));

      final s = await service.annualSummary(2025);
      expect(s.year, 2025);
      expect(s.incomeTotal, 10000);
      expect(s.expenseTotal, 3000);
      expect(s.adjustmentTotal, -100);
      expect(s.net, 6900);
    });

    test('excludes other years', () async {
      final now = DateTime.now();
      await _insert(TransactionsCompanion.insert(
        id: 'prev',
        type: 'income',
        amount: 999,
        date: DateTime(2024, 12, 31),
        createdAt: now,
        updatedAt: now,
      ));
      await _insert(TransactionsCompanion.insert(
        id: 'curr',
        type: 'income',
        amount: 100,
        date: DateTime(2025, 1, 1),
        createdAt: now,
        updatedAt: now,
      ));

      final s = await service.annualSummary(2025);
      expect(s.incomeTotal, 100);
    });
  });

  group('billsPaidInPeriod', () {
    test('counts only expenses with linkedBillId', () async {
      final now = DateTime.now();
      await _insert(TransactionsCompanion.insert(
        id: 'e1',
        type: 'expense',
        amount: 100,
        date: DateTime(2025, 3, 5),
        categoryId: Value('cat_rent'),
        linkedBillId: Value('bill_1'),
        createdAt: now,
        updatedAt: now,
      ));
      await _insert(TransactionsCompanion.insert(
        id: 'e2',
        type: 'expense',
        amount: 50,
        date: DateTime(2025, 3, 10),
        categoryId: Value('cat_groceries'),
        createdAt: now,
        updatedAt: now,
      ));
      await _insert(TransactionsCompanion.insert(
        id: 'e3',
        type: 'expense',
        amount: 80,
        date: DateTime(2025, 3, 15),
        categoryId: Value('cat_utilities'),
        linkedBillId: Value('bill_2'),
        createdAt: now,
        updatedAt: now,
      ));

      final r = await service.billsPaidInPeriod(
        DateTime(2025, 3, 1),
        DateTime(2025, 4, 1),
      );
      expect(r.count, 2);
      expect(r.totalAmount, 180);
    });

    test('bills paid only in period', () async {
      final now = DateTime.now();
      await _insert(TransactionsCompanion.insert(
        id: 'feb',
        type: 'expense',
        amount: 100,
        date: DateTime(2025, 2, 28),
        linkedBillId: Value('bill_1'),
        createdAt: now,
        updatedAt: now,
      ));
      await _insert(TransactionsCompanion.insert(
        id: 'mar',
        type: 'expense',
        amount: 100,
        date: DateTime(2025, 3, 1),
        linkedBillId: Value('bill_1'),
        createdAt: now,
        updatedAt: now,
      ));

      final r = await service.billsPaidInPeriod(
        DateTime(2025, 3, 1),
        DateTime(2025, 4, 1),
      );
      expect(r.count, 1);
      expect(r.totalAmount, 100);
    });
  });

  group('categoryBreakdown', () {
    test('sums expenses by category for month', () async {
      final now = DateTime.now();
      await _insert(TransactionsCompanion.insert(
        id: 'a1',
        type: 'expense',
        amount: 60,
        date: DateTime(2025, 4, 1),
        categoryId: Value('cat_groceries'),
        createdAt: now,
        updatedAt: now,
      ));
      await _insert(TransactionsCompanion.insert(
        id: 'a2',
        type: 'expense',
        amount: 40,
        date: DateTime(2025, 4, 5),
        categoryId: Value('cat_groceries'),
        createdAt: now,
        updatedAt: now,
      ));
      await _insert(TransactionsCompanion.insert(
        id: 'a3',
        type: 'expense',
        amount: 25,
        date: DateTime(2025, 4, 10),
        categoryId: Value('cat_dining'),
        createdAt: now,
        updatedAt: now,
      ));

      final list = await service.categoryBreakdown(2025, 4);
      expect(list.length, 2);
      final groceries = list.firstWhere((e) => e.categoryId == 'cat_groceries');
      final dining = list.firstWhere((e) => e.categoryId == 'cat_dining');
      expect(groceries.total, 100);
      expect(dining.total, 25);
    });
  });
}
