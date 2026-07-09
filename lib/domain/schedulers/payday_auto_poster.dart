import 'package:drift/drift.dart';

import '../../core/utils/date_helpers.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/repositories/recurring_income_repository.dart';
import '../models/enums.dart';
import '../services/recurring_income_service.dart';

/// On payday, auto-insert expected income when enabled and expectedAmount exists.
class PaydayAutoPoster {
  final RecurringIncomeRepository _incomeRepo;
  final RecurringIncomeService _incomeService;

  PaydayAutoPoster(this._incomeRepo, this._incomeService);

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

    final freq =
        enumFromDb<IncomeFrequency>(income.frequency, IncomeFrequency.values);
    var payday = DateTime(
      income.nextPaydayDate.year,
      income.nextPaydayDate.month,
      income.nextPaydayDate.day,
    );

    int posted = 0;
    int guard = 0;
    while (!payday.isAfter(todayStart) && guard < 1000) {
      guard++;
      final inserted = await _incomeService.postExpectedPaydayIfNeeded(
        income: income,
        payday: payday,
        amount: amount,
      );
      if (inserted) posted++;
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
}
