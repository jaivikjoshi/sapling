import 'package:flutter_test/flutter_test.dart';
import 'package:leko/domain/integrations/receipt_text_parser.dart';

void main() {
  test('extracts receipt amount tax merchant date and category', () {
    final result = const ReceiptTextParser().parse(
      attachmentId: 'receipt_1',
      text: '''
        Fresh Market
        06/16/2026
        Apples 4.50
        HST \$1.25
        Grand Total \$18.75
      ''',
    );

    expect(result.attachmentId, 'receipt_1');
    expect(result.merchant, 'Fresh Market');
    expect(result.date, DateTime(2026, 6, 16));
    expect(result.amount, 18.75);
    expect(result.taxAmount, 1.25);
    expect(result.categorySuggestion, 'Groceries');
    expect(result.confidence, greaterThan(0.7));
  });

  test('falls back to largest amount and supplied date', () {
    final fallbackDate = DateTime(2026, 6, 16);
    final result = const ReceiptTextParser().parse(
      attachmentId: 'receipt_2',
      fallbackDate: fallbackDate,
      text: '''
        Coffee Bar
        Latte \$5.50
        Tip \$1.00
      ''',
    );

    expect(result.merchant, 'Coffee Bar');
    expect(result.date, fallbackDate);
    expect(result.amount, 5.50);
    expect(result.categorySuggestion, 'Food');
  });
}
