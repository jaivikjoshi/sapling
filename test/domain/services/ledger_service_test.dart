import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/data/db/sapling_database.dart';
import 'package:sapling/data/repositories/transactions_repository.dart';
import 'package:sapling/domain/models/enums.dart';
import 'package:sapling/domain/services/ledger_service.dart';

void main() {
  late SaplingDatabase db;
  late TransactionsRepository repo;
  late LedgerService ledger;

  setUp(() {
    db = SaplingDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTransactionsRepository(db);
    ledger = LedgerService(repo);
  });

  tearDown(() => db.close());

  group('computeBalance', () {
    test('empty ledger returns 0', () async {
      expect(await ledger.computeBalance(), 0.0);
    });

    test('single income', () async {
      await ledger.addIncome(
        amount: 1000,
        date: DateTime(2025, 1, 1),
        postingType: IncomePostingType.manualOneTime,
      );
      expect(await ledger.computeBalance(), 1000.0);
    });

    test('income minus expense', () async {
      await ledger.addIncome(
        amount: 2000,
        date: DateTime(2025, 1, 1),
        postingType: IncomePostingType.manualOneTime,
      );
      await ledger.addExpense(
        amount: 150,
        date: DateTime(2025, 1, 2),
        categoryId: 'cat_groceries',
        label: SpendLabel.green,
      );
      expect(await ledger.computeBalance(), 1850.0);
    });

    test('PRD formula: income - expenses + adjustments', () async {
      await ledger.addIncome(
        amount: 3000,
        date: DateTime(2025, 1, 1),
        postingType: IncomePostingType.manualOneTime,
      );
      await ledger.addExpense(
        amount: 500,
        date: DateTime(2025, 1, 5),
        categoryId: 'cat_dining',
        label: SpendLabel.orange,
      );
      await ledger.addExpense(
        amount: 200,
        date: DateTime(2025, 1, 6),
        categoryId: 'cat_shopping',
        label: SpendLabel.red,
      );
      await ledger.addAdjustment(
        amount: 100,
        date: DateTime(2025, 1, 7),
        note: 'Found money',
      );
      // 3000 - 500 - 200 + 100 = 2400
      expect(await ledger.computeBalance(), 2400.0);
    });

    test('negative adjustment', () async {
      await ledger.addIncome(
        amount: 1000,
        date: DateTime(2025, 1, 1),
        postingType: IncomePostingType.manualOneTime,
      );
      await ledger.addAdjustment(
        amount: -200,
        date: DateTime(2025, 1, 2),
        note: 'Bank fee',
      );
      expect(await ledger.computeBalance(), 800.0);
    });

    test('multiple incomes and expenses', () async {
      await ledger.addIncome(
        amount: 1500,
        date: DateTime(2025, 1, 1),
        postingType: IncomePostingType.confirmedActual,
        source: 'Job',
      );
      await ledger.addIncome(
        amount: 500,
        date: DateTime(2025, 1, 15),
        postingType: IncomePostingType.manualOneTime,
        source: 'Freelance',
      );
      await ledger.addExpense(
        amount: 80,
        date: DateTime(2025, 1, 3),
        categoryId: 'cat_groceries',
        label: SpendLabel.green,
      );
      await ledger.addExpense(
        amount: 120,
        date: DateTime(2025, 1, 10),
        categoryId: 'cat_entertainment',
        label: SpendLabel.orange,
      );
      // 1500 + 500 - 80 - 120 = 1800
      expect(await ledger.computeBalance(), 1800.0);
    });
  });

  group('reconcile', () {
    test('creates correct positive adjustment', () async {
      await ledger.addIncome(
        amount: 1000,
        date: DateTime(2025, 1, 1),
        postingType: IncomePostingType.manualOneTime,
      );
      // Balance is 1000, real balance is 1200 → adjustment = +200
      await ledger.reconcile(1200);
      expect(await ledger.computeBalance(), 1200.0);
    });

    test('creates correct negative adjustment', () async {
      await ledger.addIncome(
        amount: 2000,
        date: DateTime(2025, 1, 1),
        postingType: IncomePostingType.manualOneTime,
      );
      // Balance is 2000, real balance is 1800 → adjustment = -200
      await ledger.reconcile(1800);
      expect(await ledger.computeBalance(), 1800.0);
    });

    test('zero adjustment when balances match', () async {
      await ledger.addIncome(
        amount: 500,
        date: DateTime(2025, 1, 1),
        postingType: IncomePostingType.manualOneTime,
      );
      await ledger.reconcile(500);
      expect(await ledger.computeBalance(), 500.0);
    });

    test('adjustment is auditable (visible in ledger)', () async {
      await ledger.addIncome(
        amount: 1000,
        date: DateTime(2025, 1, 1),
        postingType: IncomePostingType.manualOneTime,
      );
      final adjId = await ledger.reconcile(1150);

      final adj = await repo.getById(adjId);
      expect(adj.type, 'adjustment');
      expect(adj.amount, 150.0);
      expect(adj.note, 'Reconcile to bank balance');
    });

    test('reconcile from empty ledger', () async {
      await ledger.reconcile(500);
      expect(await ledger.computeBalance(), 500.0);
    });

    test('reconcile after expenses bring balance correct', () async {
      await ledger.addIncome(
        amount: 2000,
        date: DateTime(2025, 1, 1),
        postingType: IncomePostingType.manualOneTime,
      );
      await ledger.addExpense(
        amount: 300,
        date: DateTime(2025, 1, 5),
        categoryId: 'cat_groceries',
        label: SpendLabel.green,
      );
      // Balance = 1700, reconcile to 1500 → adj = -200
      await ledger.reconcile(1500);
      expect(await ledger.computeBalance(), 1500.0);
    });
  });
}
