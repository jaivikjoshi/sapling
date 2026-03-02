import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/data/db/sapling_database.dart';
import 'package:sapling/data/repositories/persons_repository.dart';
import 'package:sapling/domain/services/split_service.dart';
import 'package:sapling/data/repositories/split_entries_repository.dart';
import 'package:sapling/data/repositories/split_shares_repository.dart';
import 'package:sapling/data/repositories/transactions_repository.dart';
import 'package:sapling/domain/services/split_service.dart';

void main() {
  late SaplingDatabase db;
  late SplitEntriesRepository entriesRepo;
  late SplitSharesRepository sharesRepo;
  late TransactionsRepository txnRepo;
  late PersonsRepository personsRepo;
  late SplitService service;

  setUp(() async {
    db = SaplingDatabase.forTesting(NativeDatabase.memory());
    entriesRepo = SplitEntriesRepository(db);
    sharesRepo = SplitSharesRepository(db);
    txnRepo = TransactionsRepository(db);
    personsRepo = PersonsRepository(db);

    final now = DateTime(2025, 1, 15);
    await personsRepo.insert(PersonsCompanion.insert(
      id: 'person_a',
      name: 'Alice',
      createdAt: now,
      updatedAt: now,
    ));
    await personsRepo.insert(PersonsCompanion.insert(
      id: 'person_b',
      name: 'Bob',
      createdAt: now,
      updatedAt: now,
    ));

    service = SplitService(entriesRepo, sharesRepo, txnRepo, personsRepo);
  });

  tearDown(() => db.close());

  group('createSplit', () {
    test('equal split produces correct share amounts and sum equals total', () async {
      final id = await service.createSplit(
        description: 'Dinner',
        totalAmount: 30,
        paidBy: kSplitPaidByYou,
        shares: [
          (personId: kSplitPaidByYou, shareAmount: 10),
          (personId: 'person_a', shareAmount: 10),
          (personId: 'person_b', shareAmount: 10),
        ],
      );
      expect(id, isNotEmpty);

      final entry = await service.getSplitById(id);
      expect(entry != null, true);
      expect(entry!.totalAmount, 30.0);
      expect(entry.status, 'open');

      final shares = await service.getSharesForSplit(id);
      expect(shares.length, 3);
      final sum = shares.fold<double>(0, (s, sh) => s + sh.shareAmount);
      expect(sum, closeTo(30, 0.01));
    });

    test('rejects totalAmount <= 0', () async {
      expect(
        () => service.createSplit(
          description: 'X',
          totalAmount: 0,
          paidBy: kSplitPaidByYou,
          shares: [(personId: kSplitPaidByYou, shareAmount: 0)],
        ),
        throwsArgumentError,
      );
    });

    test('rejects shares sum not equal to total', () async {
      expect(
        () => service.createSplit(
          description: 'X',
          totalAmount: 100,
          paidBy: kSplitPaidByYou,
          shares: [
            (personId: kSplitPaidByYou, shareAmount: 50),
            (personId: 'person_a', shareAmount: 40),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('computeBalancesByPerson', () {
    test('you paid: person share is owed to you', () async {
      await service.createSplit(
        description: 'Lunch',
        totalAmount: 60,
        paidBy: kSplitPaidByYou,
        shares: [
          (personId: kSplitPaidByYou, shareAmount: 20),
          (personId: 'person_a', shareAmount: 20),
          (personId: 'person_b', shareAmount: 20),
        ],
      );

      final balances = await service.computeBalancesByPerson();
      expect(balances.containsKey('person_a'), true);
      expect(balances.containsKey('person_b'), true);
      expect(balances['person_a']!.owedToYou, 20);
      expect(balances['person_a']!.youOwe, 0);
      expect(balances['person_b']!.owedToYou, 20);
      expect(balances['person_b']!.youOwe, 0);
    });

    test('person paid: your share is you owe', () async {
      await service.createSplit(
        description: 'Dinner',
        totalAmount: 45,
        paidBy: 'person_a',
        shares: [
          (personId: kSplitPaidByYou, shareAmount: 15),
          (personId: 'person_a', shareAmount: 15),
          (personId: 'person_b', shareAmount: 15),
        ],
      );

      final balances = await service.computeBalancesByPerson();
      expect(balances['person_a']!.youOwe, 15);
      expect(balances['person_a']!.owedToYou, 0);
    });

    test('multiple splits aggregate correctly', () async {
      await service.createSplit(
        description: 'S1',
        totalAmount: 30,
        paidBy: kSplitPaidByYou,
        shares: [
          (personId: kSplitPaidByYou, shareAmount: 10),
          (personId: 'person_a', shareAmount: 20),
        ],
      );
      await service.createSplit(
        description: 'S2',
        totalAmount: 24,
        paidBy: 'person_a',
        shares: [
          (personId: kSplitPaidByYou, shareAmount: 12),
          (personId: 'person_a', shareAmount: 12),
        ],
      );

      final balances = await service.computeBalancesByPerson();
      // person_a owes you 20 (S1), you owe person_a 12 (S2) → net owed to you 8
      expect(balances['person_a']!.owedToYou, 20);
      expect(balances['person_a']!.youOwe, 12);
      expect(balances['person_a']!.netOwedToYou, 8);
    });
  });

  group('markSettled', () {
    test('settlement updates balances correctly (excluded from open)', () async {
      final id = await service.createSplit(
        description: 'Trip',
        totalAmount: 100,
        paidBy: kSplitPaidByYou,
        shares: [
          (personId: kSplitPaidByYou, shareAmount: 50),
          (personId: 'person_a', shareAmount: 50),
        ],
      );

      var balances = await service.computeBalancesByPerson();
      expect(balances['person_a']!.owedToYou, 50);

      await service.markSettled(id);

      balances = await service.computeBalancesByPerson();
      expect(balances.containsKey('person_a'), false);
    });

    test('only specified split is settled', () async {
      final id1 = await service.createSplit(
        description: 'S1',
        totalAmount: 20,
        paidBy: kSplitPaidByYou,
        shares: [
          (personId: kSplitPaidByYou, shareAmount: 10),
          (personId: 'person_a', shareAmount: 10),
        ],
      );
      await service.createSplit(
        description: 'S2',
        totalAmount: 20,
        paidBy: kSplitPaidByYou,
        shares: [
          (personId: kSplitPaidByYou, shareAmount: 10),
          (personId: 'person_a', shareAmount: 10),
        ],
      );

      await service.markSettled(id1);

      final balances = await service.computeBalancesByPerson();
      expect(balances['person_a']!.owedToYou, 10);
    });
  });

  group('updateSplitFromExpenseAmount', () {
    test('updates total and rescales shares', () async {
      final id = await service.createSplit(
        description: 'Groceries',
        totalAmount: 60,
        paidBy: kSplitPaidByYou,
        shares: [
          (personId: kSplitPaidByYou, shareAmount: 30),
          (personId: 'person_a', shareAmount: 30),
        ],
      );

      await service.updateSplitFromExpenseAmount(id, 90);

      final entry = await service.getSplitById(id);
      expect(entry!.totalAmount, 90);
      final shares = await service.getSharesForSplit(id);
      final sum = shares.fold<double>(0, (s, sh) => s + sh.shareAmount);
      expect(sum, closeTo(90, 0.02));
    });
  });
}
