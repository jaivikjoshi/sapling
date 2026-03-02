import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/date_helpers.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/sapling_database.dart';
import '../../data/repositories/recurring_income_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../models/enums.dart';

/// On payday, auto-insert expected income when enabled and expectedAmount exists.
class PaydayAutoPoster {
  final RecurringIncomeRepository _incomeRepo;
  final TransactionsRepository _txnRepo;
  static const _uuid = Uuid();

  PaydayAutoPoster(this._incomeRepo, this._txnRepo);

  /// Run for [today]. For each income with nextPaydayDate == today and
  /// paydayBehavior == autoPostExpected and expectedAmount > 0, insert income
  /// if not already posted for this payday.
  Future<int> runForDate(DateTime today) async {
    final incomes = await _incomeRepo.getAll();
    final todayStart = DateTime(today.year, today.month, today.day);
    int posted = 0;
    for (final income in incomes) {
      final payday = DateTime(
        income.nextPaydayDate.year,
        income.nextPaydayDate.month,
        income.nextPaydayDate.day,
      );
      if (payday != todayStart) continue;
      final behavior =
          enumFromDb<PaydayBehavior>(income.paydayBehavior, PaydayBehavior.values);
      if (behavior != PaydayBehavior.autoPostExpected) continue;
      final amount = income.expectedAmount;
      if (amount == null || amount <= 0) continue;
      final already = await _hasIncomeForRecurringOnDate(
        income.id,
        todayStart,
      );
      if (already) continue;
      await _postExpected(income, todayStart, amount);
      await _advancePayday(income);
      posted++;
    }
    return posted;
  }

  Future<bool> _hasIncomeForRecurringOnDate(
    String recurringIncomeId,
    DateTime dateStart,
  ) async {
    final dateEnd = dateStart.add(const Duration(days: 1));
    final txns = await _txnRepo.getByDateRange(dateStart, dateEnd);
    return txns.any((t) =>
        t.type == 'income' && t.linkedRecurringIncomeId == recurringIncomeId);
  }

  Future<void> _postExpected(
    RecurringIncome income,
    DateTime date,
    double amount,
  ) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _txnRepo.insert(TransactionsCompanion.insert(
      id: id,
      type: enumToDb(TransactionType.income),
      amount: amount,
      date: date,
      incomePostingType: Value(enumToDb(IncomePostingType.autoPostedExpected)),
      linkedRecurringIncomeId: Value(income.id),
      note: Value('Auto-posted: ${income.name}'),
      createdAt: now,
      updatedAt: now,
    ));
  }

  Future<void> _advancePayday(RecurringIncome income) async {
    final freq =
        enumFromDb<IncomeFrequency>(income.frequency, IncomeFrequency.values);
    final next = advanceByIncomeFrequency(income.nextPaydayDate, freq);
    await _incomeRepo.updateById(
      income.id,
      RecurringIncomesCompanion(
        nextPaydayDate: Value(next),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
