import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/data/db/sapling_database.dart';
import 'package:sapling/data/repositories/bills_repository.dart';
import 'package:sapling/data/repositories/transactions_repository.dart';
import 'package:sapling/domain/models/enums.dart';
import 'package:sapling/domain/services/bills_service.dart';

void main() {
  late SaplingDatabase db;
  late BillsRepository billsRepo;
  late TransactionsRepository txnRepo;
  late BillsService service;

  setUp(() {
    db = SaplingDatabase.forTesting(NativeDatabase.memory());
    billsRepo = DriftBillsRepository(db);
    txnRepo = DriftTransactionsRepository(db);
    service = BillsService(billsRepo, txnRepo);
  });

  tearDown(() => db.close());

  group('validation', () {
    test('empty name returns error', () {
      expect(BillsService.validateName(''), isNotNull);
      expect(BillsService.validateName('  '), isNotNull);
    });

    test('valid name returns null', () {
      expect(BillsService.validateName('Rent'), isNull);
    });

    test('null amount returns error', () {
      expect(BillsService.validateAmount(null), isNotNull);
    });

    test('zero amount returns error', () {
      expect(BillsService.validateAmount(0), isNotNull);
    });

    test('negative amount returns error', () {
      expect(BillsService.validateAmount(-50), isNotNull);
    });

    test('positive amount returns null', () {
      expect(BillsService.validateAmount(100), isNull);
    });
  });

  group('computeNextDueDate (pure)', () {
    test('weekly advances by 7 days', () {
      final d = DateTime(2025, 6, 1);
      expect(
        BillsService.computeNextDueDate(d, BillFrequency.weekly),
        DateTime(2025, 6, 8),
      );
    });

    test('biweekly advances by 14 days', () {
      final d = DateTime(2025, 6, 1);
      expect(
        BillsService.computeNextDueDate(d, BillFrequency.biweekly),
        DateTime(2025, 6, 15),
      );
    });

    test('monthly advances to same day next month', () {
      final d = DateTime(2025, 1, 15);
      expect(
        BillsService.computeNextDueDate(d, BillFrequency.monthly),
        DateTime(2025, 2, 15),
      );
    });

    test('monthly clamps to end-of-month', () {
      final d = DateTime(2025, 1, 31);
      expect(
        BillsService.computeNextDueDate(d, BillFrequency.monthly),
        DateTime(2025, 2, 28),
      );
    });

    test('quarterly advances by 3 months', () {
      final d = DateTime(2025, 1, 15);
      expect(
        BillsService.computeNextDueDate(d, BillFrequency.quarterly),
        DateTime(2025, 4, 15),
      );
    });

    test('yearly advances by 12 months', () {
      final d = DateTime(2025, 3, 1);
      expect(
        BillsService.computeNextDueDate(d, BillFrequency.yearly),
        DateTime(2026, 3, 1),
      );
    });

    test('yearly Feb 29 on leap year clamps to Feb 28 next year', () {
      final d = DateTime(2024, 2, 29);
      expect(
        BillsService.computeNextDueDate(d, BillFrequency.yearly),
        DateTime(2025, 2, 28),
      );
    });

    test('quarterly from Nov goes to Feb', () {
      final d = DateTime(2025, 11, 15);
      expect(
        BillsService.computeNextDueDate(d, BillFrequency.quarterly),
        DateTime(2026, 2, 15),
      );
    });
  });

  group('CRUD', () {
    test('create and getById returns correct bill', () async {
      final id = await service.create(
        name: 'Rent',
        amount: 1500,
        frequency: BillFrequency.monthly,
        nextDueDate: DateTime(2025, 4, 1),
        categoryId: 'cat-housing',
        defaultLabel: SpendLabel.green,
      );

      final bill = await service.getById(id);
      expect(bill.name, 'Rent');
      expect(bill.amount, 1500);
    });

    test('update modifies fields', () async {
      final id = await service.create(
        name: 'Old',
        amount: 100,
        frequency: BillFrequency.monthly,
        nextDueDate: DateTime(2025, 5, 1),
        categoryId: 'cat-1',
        defaultLabel: SpendLabel.green,
      );

      await service.update(
        id: id,
        name: 'New',
        amount: 200,
        frequency: BillFrequency.biweekly,
        nextDueDate: DateTime(2025, 5, 15),
        categoryId: 'cat-2',
        defaultLabel: SpendLabel.orange,
      );

      final bill = await service.getById(id);
      expect(bill.name, 'New');
      expect(bill.amount, 200);
    });

    test('delete removes the bill', () async {
      final id = await service.create(
        name: 'Temp',
        amount: 50,
        frequency: BillFrequency.weekly,
        nextDueDate: DateTime(2025, 6, 1),
        categoryId: 'cat-1',
        defaultLabel: SpendLabel.red,
      );

      await service.delete(id);
      final all = await billsRepo.getAll();
      expect(all.where((b) => b.id == id).isEmpty, true);
    });
  });

  group('markPaid', () {
    test('creates expense transaction linked to bill', () async {
      final billId = await service.create(
        name: 'Electricity',
        amount: 120,
        frequency: BillFrequency.monthly,
        nextDueDate: DateTime(2025, 4, 1),
        categoryId: 'cat-utils',
        defaultLabel: SpendLabel.green,
      );

      final result = await service.markPaid(
        billId: billId,
        paidDate: DateTime(2025, 4, 1),
      );

      expect(result.paidAmount, 120);
      expect(result.transactionId, isNotEmpty);

      final txn = await txnRepo.getById(result.transactionId);
      expect(txn.type, 'expense');
      expect(txn.amount, 120);
      expect(txn.linkedBillId, billId);
      expect(txn.categoryId, 'cat-utils');
    });

    test('advances nextDueDate by frequency', () async {
      final billId = await service.create(
        name: 'Internet',
        amount: 80,
        frequency: BillFrequency.monthly,
        nextDueDate: DateTime(2025, 3, 15),
        categoryId: 'cat-1',
        defaultLabel: SpendLabel.green,
      );

      final result = await service.markPaid(billId: billId);
      expect(result.updatedBill.nextDueDate, DateTime(2025, 4, 15));
    });

    test('accepts amount override without changing bill amount', () async {
      final billId = await service.create(
        name: 'Phone',
        amount: 60,
        frequency: BillFrequency.monthly,
        nextDueDate: DateTime(2025, 5, 1),
        categoryId: 'cat-1',
        defaultLabel: SpendLabel.orange,
      );

      final result = await service.markPaid(
        billId: billId,
        amountOverride: 75,
      );

      expect(result.paidAmount, 75);

      final bill = await service.getById(billId);
      expect(bill.amount, 60);
    });

    test('expense reduces computed balance', () async {
      final billId = await service.create(
        name: 'Rent',
        amount: 1000,
        frequency: BillFrequency.monthly,
        nextDueDate: DateTime(2025, 4, 1),
        categoryId: 'cat-1',
        defaultLabel: SpendLabel.green,
      );

      final balBefore = await txnRepo.computeBalance();
      expect(balBefore, 0);

      await service.markPaid(billId: billId);

      final balAfter = await txnRepo.computeBalance();
      expect(balAfter, -1000);
    });

    test('transaction note includes bill name', () async {
      final billId = await service.create(
        name: 'Netflix',
        amount: 15.99,
        frequency: BillFrequency.monthly,
        nextDueDate: DateTime(2025, 6, 1),
        categoryId: 'cat-1',
        defaultLabel: SpendLabel.red,
      );

      final result = await service.markPaid(billId: billId);
      final txn = await txnRepo.getById(result.transactionId);
      expect(txn.note, contains('Netflix'));
    });

    test('quarterly bill advances by 3 months', () async {
      final billId = await service.create(
        name: 'Insurance',
        amount: 300,
        frequency: BillFrequency.quarterly,
        nextDueDate: DateTime(2025, 1, 15),
        categoryId: 'cat-1',
        defaultLabel: SpendLabel.green,
      );

      final result = await service.markPaid(billId: billId);
      expect(result.updatedBill.nextDueDate, DateTime(2025, 4, 15));
    });

    test('yearly bill advances by 12 months', () async {
      final billId = await service.create(
        name: 'Domain Renewal',
        amount: 12,
        frequency: BillFrequency.yearly,
        nextDueDate: DateTime(2025, 7, 1),
        categoryId: 'cat-1',
        defaultLabel: SpendLabel.orange,
      );

      final result = await service.markPaid(billId: billId);
      expect(result.updatedBill.nextDueDate, DateTime(2026, 7, 1));
    });
  });
}
