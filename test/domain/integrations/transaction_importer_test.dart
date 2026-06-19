import 'package:flutter_test/flutter_test.dart';
import 'package:leko/domain/integrations/transaction_importer.dart';

void main() {
  group('ImportedTransactionDraft.isImportable', () {
    test('accepts positive finite amounts', () {
      final draft = ImportedTransactionDraft(
        sourceId: 'a',
        source: TransactionImportSource.bankAggregator,
        amount: 12.5,
        date: _day,
      );
      expect(draft.isImportable, isTrue);
    });

    test('rejects zero, negative, and non-finite amounts', () {
      expect(
        ImportedTransactionDraft(
          sourceId: 'zero',
          source: TransactionImportSource.bankAggregator,
          amount: 0,
          date: _day,
        ).isImportable,
        isFalse,
      );
      expect(
        ImportedTransactionDraft(
          sourceId: 'negative',
          source: TransactionImportSource.bankAggregator,
          amount: -1,
          date: _day,
        ).isImportable,
        isFalse,
      );
      expect(
        ImportedTransactionDraft(
          sourceId: 'nan',
          source: TransactionImportSource.bankAggregator,
          amount: double.nan,
          date: _day,
        ).isImportable,
        isFalse,
      );
    });
  });
}

final _day = DateTime(2026, 6, 16);
