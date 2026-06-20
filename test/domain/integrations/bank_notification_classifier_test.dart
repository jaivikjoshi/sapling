import 'package:flutter_test/flutter_test.dart';

import 'package:leko/domain/integrations/bank_notification_classifier.dart';

void main() {
  group('BankNotificationClassifier', () {
    test('classifies deposits and received transfers as income', () {
      expect(
        BankNotificationClassifier.typeFor(
          'Deposit of \$500.00 credited to your account',
        ),
        'income',
      );
      expect(
        BankNotificationClassifier.typeFor(
          'Interac e-Transfer: You received \$250.00 from Alex',
        ),
        'income',
      );
      expect(
        BankNotificationClassifier.typeFor('Payroll deposit \$1,842.10'),
        'income',
      );
    });

    test('classifies purchases and withdrawals as expense', () {
      expect(
        BankNotificationClassifier.typeFor(
          'Purchase of \$12.34 at STARBUCKS',
        ),
        'expense',
      );
      expect(
        BankNotificationClassifier.typeFor(
          'Withdrawal of \$100.00 from ATM',
        ),
        'expense',
      );
      expect(
        BankNotificationClassifier.typeFor(
          'You paid \$45.00 to Hydro One',
        ),
        'expense',
      );
    });
  });
}
