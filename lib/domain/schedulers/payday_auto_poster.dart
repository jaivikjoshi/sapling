import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/date_helpers.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/repositories/recurring_income_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../models/enums.dart';

/// On payday, auto-insert expected income when enabled and expectedAmount exists.
class PaydayAutoPoster {
  final RecurringIncomeRepository _incomeRepo;
  final TransactionsRepository _txnRepo;
  static const _uuid = Uuid();

  PaydayAutoPoster(this._incomeRepo, this._txnRepo);

  /// Run for [today]. For each income with paydayBehavior == autoPostExpected
  /// and a positive expectedAmount, post the paycheck for every payday that
  /// has occurred on or before [today] and advance `nextPaydayDate` forward.
  /// This catches up missed paydays (e.g. if the user hasn't opened the app
  /// for a few days) while staying idempotent via a per-date existence check.
  Future<int> runForDate(DateTime today) async {
    final incomes = await _incomeRepo.getAll();
    final todayStart = DateTime(today.year, today.month, today.day);
    int posted = 0;
    for (final income in incomes) {
      posted += await _runForIncome(income, todayStart);
    }
    return posted;
  }

  Future<int> _runForIncome(RecurringIncome income, DateTime todayStart) async {
    final behavior = enumFromDb<PaydayBehavior>(
      income.paydayBehavior,
      PaydayBehavior.values,
    );
    if (behavior != PaydayBehavior.autoPostExpected) return 0;
    final amount = income.expectedAmount;
    if (amount == null || amount <= 0) return 0;

    final freq = enumFromDb<IncomeFrequency>(
      income.frequency,
      IncomeFrequency.values,
    );
    var payday = DateTime(
      income.nextPaydayDate.year,
      income.nextPaydayDate.month,
      income.nextPaydayDate.day,
    );

    int posted = 0;
    int guard = 0;
    while (!payday.isAfter(todayStart) && guard < 1000) {
      guard++;
      final already = await _hasIncomeForRecurringOnDate(income.id, payday);
      if (!already) {
        await _postExpected(income, payday, amount);
        posted++;
      }
      payday = advanceByIncomeFrequency(payday, freq);
    }

    if (posted > 0 || payday != income.nextPaydayDate) {
      await _incomeRepo.updateById(
        income.id,
        RecurringIncomesCompanion(
          nextPaydayDate: Value(payday),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
    return posted;
  }

  Future<bool> _hasIncomeForRecurringOnDate(
    String recurringIncomeId,
    DateTime dateStart,
  ) async {
    final dateEnd = dateStart.add(const Duration(days: 1));
    final txns = await _txnRepo.getByDateRange(dateStart, dateEnd);
    return txns.any(
      (t) =>
          t.type == 'income' && t.linkedRecurringIncomeId == recurringIncomeId,
    );
  }

  Future<void> _postExpected(
    RecurringIncome income,
    DateTime date,
    double amount,
  ) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _txnRepo.insert(
      Transaction(
        id: id,
        type: enumToDb(TransactionType.income),
        amount: amount,
        date: date,
        incomePostingType: enumToDb(IncomePostingType.autoPostedExpected),
        linkedRecurringIncomeId: income.id,
        note: 'Auto-posted: ${income.name}',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
