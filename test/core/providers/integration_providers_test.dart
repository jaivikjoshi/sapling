import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leko/core/providers/integration_providers.dart';
import 'package:leko/core/providers/ledger_providers.dart';
import 'package:leko/data/db/leko_database.dart';
import 'package:leko/data/repositories/transactions_repository.dart';
import 'package:leko/domain/integrations/transaction_importer.dart';
import 'package:leko/domain/models/enums.dart';

void main() {
  late LekoDatabase db;
  late DriftTransactionsRepository txnRepo;
  late ProviderContainer container;

  setUp(() async {
    db = LekoDatabase.forTesting(NativeDatabase.memory());
    txnRepo = DriftTransactionsRepository(db);
    container = ProviderContainer(
      overrides: [
        transactionsRepositoryProvider.overrideWithValue(txnRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('importApproved ignores zero-amount drafts', () async {
    final controller = container.read(
      transactionReviewControllerProvider.notifier,
    );
    controller.addDrafts([
      ImportedTransactionDraft(
        sourceId: 'zero-amount',
        source: TransactionImportSource.bankNotification,
        amount: 0,
        date: DateTime(2026, 5, 1),
        reviewStatus: ImportReviewStatus.approved,
      ),
    ]);

    final result = await controller.importApproved();

    expect(result.createdCount, 0);
    expect(result.skippedCount, 1);
    expect(await txnRepo.getAll(), isEmpty);
  });

  test('concurrent importApproved only creates one ledger row', () async {
    final controller = container.read(
      transactionReviewControllerProvider.notifier,
    );
    controller.addDrafts([
      ImportedTransactionDraft(
        sourceId: 'dup-import',
        source: TransactionImportSource.bankNotification,
        amount: 42,
        date: DateTime(2026, 5, 1),
        merchant: 'Coffee Shop',
        reviewStatus: ImportReviewStatus.approved,
      ),
    ]);

    final results = await Future.wait([
      controller.importApproved(),
      controller.importApproved(),
    ]);

    final created = results.fold<int>(
      0,
      (sum, result) => sum + result.createdCount,
    );
    expect(created, 1);
    expect((await txnRepo.getAll()).length, 1);
  });
}
