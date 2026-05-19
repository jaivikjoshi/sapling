import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leko/data/db/leko_database.dart';
import 'package:leko/data/repositories/bills_repository.dart';
import 'package:leko/data/repositories/transactions_repository.dart';
import 'package:leko/domain/schedulers/bill_auto_poster.dart';

void main() {
  late LekoDatabase db;
  late DriftBillsRepository billsRepo;
  late DriftTransactionsRepository txnRepo;
  late BillAutoPoster poster;

  setUp(() async {
    db = LekoDatabase.forTesting(NativeDatabase.memory());
    billsRepo = DriftBillsRepository(db);
    txnRepo = DriftTransactionsRepository(db);
    poster = BillAutoPoster(billsRepo, txnRepo);
  });

  tearDown(() => db.close());

  group('BillAutoPoster', () {
    test('does not post or advance when autopay is disabled', () async {
      final due = DateTime(2026, 5, 16);
      await billsRepo.insert(
        BillsCompanion.insert(
          id: 'bill-reminder',
          name: 'Rent',
          amount: 1200,
          nextDueDate: due,
          categoryId: 'cat-1',
          autopay: const Value(false),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      final posted = await poster.runForDate(DateTime(2026, 5, 16, 14, 0));
      expect(posted, 0);

      final txns = await txnRepo.getAll();
      expect(txns, isEmpty);

      final reloaded = await billsRepo.getById('bill-reminder');
      expect(reloaded.nextDueDate, due);
    });

    test('posts expense and advances due date when autopay is enabled', () async {
      final due = DateTime(2026, 5, 16);
      await billsRepo.insert(
        BillsCompanion.insert(
          id: 'bill-auto',
          name: 'Streaming',
          amount: 15,
          nextDueDate: due,
          categoryId: 'cat-1',
          autopay: const Value(true),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      final posted = await poster.runForDate(DateTime(2026, 5, 16, 9, 0));
      expect(posted, 1);

      final txns = await txnRepo.getAll();
      expect(txns, hasLength(1));
      expect(txns.single.linkedBillId, 'bill-auto');
      expect(txns.single.amount, 15);

      final reloaded = await billsRepo.getById('bill-auto');
      expect(reloaded.nextDueDate, DateTime(2026, 6, 16));
    });
  });
}
