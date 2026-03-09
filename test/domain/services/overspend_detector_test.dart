import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/data/db/sapling_database.dart';
import 'package:sapling/data/repositories/bills_repository.dart';
import 'package:sapling/data/repositories/recurring_income_repository.dart';
import 'package:sapling/data/repositories/transactions_repository.dart';
import 'package:sapling/domain/models/enums.dart';
import 'package:sapling/domain/models/settings_model.dart';
import 'package:sapling/domain/services/allowance_engine.dart';
import 'package:sapling/domain/services/ledger_service.dart';
import 'package:sapling/domain/services/overspend_detector.dart';

void main() {
  late SaplingDatabase db;
  late TransactionsRepository txnRepo;
  late BillsRepository billsRepo;
  late RecurringIncomeRepository incomeRepo;
  late AllowanceEngine engine;
  late LedgerService ledger;
  late OverspendDetector detector;

  setUp(() {
    db = SaplingDatabase.forTesting(NativeDatabase.memory());
    txnRepo = DriftTransactionsRepository(db);
    billsRepo = DriftBillsRepository(db);
    incomeRepo = DriftRecurringIncomeRepository(db);
    engine = AllowanceEngine(txnRepo, billsRepo, incomeRepo, null);
    ledger = LedgerService(txnRepo);
    detector = OverspendDetector(engine, txnRepo);
  });

  tearDown(() => db.close());

  final settings = UserSettings.defaults.copyWith(
    rolloverResetType: RolloverResetType.monthly,
    onboardingCompleted: true,
  );

  group('OverspendDetector', () {
    test('no overspend when no expenses', () async {
      await ledger.addIncome(
        amount: 3000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );

      final result = await detector.detect(settings: settings);
      expect(result.isOverspent, false);
      expect(result.overspendAmount, 0);
    });

    test('detects overspend when spend exceeds allowance', () async {
      // Zero balance + large expense today = overspend
      await ledger.addExpense(
        amount: 500,
        date: DateTime.now(),
        categoryId: 'cat-1',
        label: SpendLabel.red,
      );

      final result = await detector.detect(settings: settings);
      // With no income, allowance is 0, spend is 500 → overspent
      expect(result.isOverspent, true);
      expect(result.overspendAmount, greaterThan(0));
      expect(result.spendToday, 500);
      expect(result.allowanceToday, 0);
    });

    test('no overspend when income covers expense', () async {
      await ledger.addIncome(
        amount: 10000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );
      await ledger.addExpense(
        amount: 10,
        date: DateTime.now(),
        categoryId: 'cat-1',
        label: SpendLabel.green,
      );

      final result = await detector.detect(settings: settings);
      expect(result.isOverspent, false);
    });

    test('overspend amount equals spend minus allowance', () async {
      await ledger.addIncome(
        amount: 100,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );

      // Spend all of it and more
      final now = DateTime.now();
      final daysLeft = DateTime(now.year, now.month + 1)
              .difference(DateTime(now.year, now.month, now.day))
              .inDays;
      final allowancePerDay = 100.0 / daysLeft;
      final overAmount = allowancePerDay + 50;

      await ledger.addExpense(
        amount: overAmount,
        date: now,
        categoryId: 'cat-1',
        label: SpendLabel.red,
      );

      final result = await detector.detect(settings: settings);
      expect(result.isOverspent, true);
      expect(result.overspendAmount, closeTo(50, 5));
    });

    test('only counts today expenses for spendToday', () async {
      await ledger.addIncome(
        amount: 5000,
        date: DateTime.now(),
        postingType: IncomePostingType.manualOneTime,
      );

      // Yesterday's expense should NOT count as spendToday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await ledger.addExpense(
        amount: 4000,
        date: yesterday,
        categoryId: 'cat-1',
        label: SpendLabel.red,
      );

      // Small expense today
      await ledger.addExpense(
        amount: 5,
        date: DateTime.now(),
        categoryId: 'cat-1',
        label: SpendLabel.green,
      );

      final result = await detector.detect(settings: settings);
      expect(result.spendToday, 5);
    });
  });
}
