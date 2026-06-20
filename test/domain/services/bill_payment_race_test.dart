import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leko/data/db/leko_database.dart';
import 'package:leko/data/repositories/bills_repository.dart';
import 'package:leko/data/repositories/transactions_repository.dart';
import 'package:leko/domain/schedulers/bill_auto_poster.dart';
import 'package:leko/domain/services/bills_service.dart';

void main() {
  late LekoDatabase db;
  late DriftBillsRepository billsRepo;
  late DriftTransactionsRepository txnRepo;
  late BillsService billsService;
  late BillAutoPoster poster;

  setUp(() async {
    db = LekoDatabase.forTesting(NativeDatabase.memory());
    billsRepo = DriftBillsRepository(db);
    txnRepo = DriftTransactionsRepository(db);
    billsService = BillsService(billsRepo, txnRepo);
    poster = BillAutoPoster(billsRepo, txnRepo);
  });

  tearDown(() => db.close());

  test(
    'markPaid overlapping BillAutoPoster only posts one expense',
    () async {
      final due = DateTime(2026, 5, 16);
      await billsRepo.insert(
        BillsCompanion.insert(
          id: 'bill-overlap',
          name: 'Streaming',
          amount: 15,
          nextDueDate: due,
          categoryId: 'cat-1',
          autopay: const Value(true),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      await Future.wait([
        poster.runForDate(DateTime(2026, 5, 16, 9, 0)),
        billsService.markPaid(
          billId: 'bill-overlap',
          paidDate: DateTime(2026, 5, 16),
        ),
      ]);

      final txns = await txnRepo.getAll();
      expect(txns.where((t) => t.linkedBillId == 'bill-overlap'), hasLength(1));
      expect(
        (await billsRepo.getById('bill-overlap')).nextDueDate,
        DateTime(2026, 6, 16),
      );
    },
  );
}
