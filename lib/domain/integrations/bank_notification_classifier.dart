/// Classifies bank notification text as income or expense.
class BankNotificationClassifier {
  const BankNotificationClassifier._();

  static const _incomeSignals = [
    'received',
    'deposited',
    'deposit',
    'credited to',
    'credit to your',
    'refund',
    'reversal',
    'payroll',
    'salary',
    'direct deposit',
    'money received',
    'e-transfer received',
    'interac e-transfer: you received',
  ];

  static const _expenseSignals = [
    'purchase',
    'spent',
    'withdrawal',
    'withdrawn',
    'debited',
    'debit',
    'paid to',
    'payment to',
    'you paid',
    'you sent',
    'e-transfer sent',
    'charge at',
    'charged',
  ];

  static String typeFor(String content) {
    final lower = content.toLowerCase();
    final incomeScore = _incomeSignals.where(lower.contains).length;
    final expenseScore = _expenseSignals.where(lower.contains).length;
    return incomeScore > expenseScore ? 'income' : 'expense';
  }
}
