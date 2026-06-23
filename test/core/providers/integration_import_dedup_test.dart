import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leko/core/providers/auth_providers.dart';
import 'package:leko/core/providers/db_provider.dart';
import 'package:leko/core/providers/integration_providers.dart';
import 'package:leko/core/providers/ledger_providers.dart';
import 'package:leko/core/utils/enum_serialization.dart';
import 'package:leko/data/db/leko_database.dart';
import 'package:leko/domain/integrations/transaction_importer.dart';
import 'package:leko/domain/models/enums.dart';

void main() {
  late LekoDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = LekoDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWithValue(null),
        databaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test(
    'importApproved skips drafts whose sourceId was already imported even when '
    'merchant text differs',
    () async {
      final ledger = container.read(ledgerServiceProvider);
      await ledger.addExpense(
        amount: 42.50,
        date: DateTime(2025, 6, 1),
        categoryId: 'cat_other',
        label: SpendLabel.green,
        note:
            'AMZN • Imported from ${enumToDb(TransactionImportSource.bankAggregator)}:txn-123',
      );

      final controller =
          container.read(transactionReviewControllerProvider.notifier);
      controller.addDrafts([
        ImportedTransactionDraft(
          sourceId: 'txn-123',
          source: TransactionImportSource.bankAggregator,
          amount: 42.50,
          date: DateTime(2025, 6, 1),
          merchant: 'Amazon.com',
          reviewStatus: ImportReviewStatus.approved,
        ),
      ]);

      final result = await controller.importApproved();

      expect(result.createdCount, 0);
      expect(result.skippedCount, 1);
      expect((await container.read(ledgerServiceProvider).watchRecent(limit: 10).first).length, 1);
    },
  );
}
