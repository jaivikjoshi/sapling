import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/date_helpers.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/repositories/recurring_income_repository.dart';
import '../models/enums.dart';

class RecurringIncomeService {
  final RecurringIncomeRepository _repo;
  static const _uuid = Uuid();

  RecurringIncomeService(this._repo);

  Stream<List<RecurringIncome>> watchAll() => _repo.watchAll();

  Future<RecurringIncome> getById(String id) => _repo.getById(id);

  static String? validateAutoPost({
    required PaydayBehavior behavior,
    required double? expectedAmount,
  }) {
    if (behavior == PaydayBehavior.autoPostExpected &&
        (expectedAmount == null || expectedAmount <= 0)) {
      return 'Auto-post requires a positive expected amount.';
    }
    return null;
  }

  static String? validateName(String name) {
    if (name.trim().isEmpty) return 'Name is required.';
    return null;
  }

  Future<String> create({
    required String name,
    required IncomeFrequency frequency,
    required DateTime nextPaydayDate,
    double? expectedAmount,
    required PaydayBehavior paydayBehavior,
    bool isPaydayAnchor = false,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    if (isPaydayAnchor) await _repo.clearPaydayAnchor();

    await _repo.insert(RecurringIncomesCompanion.insert(
      id: id,
      name: name.trim(),
      frequency: Value(enumToDb(frequency)),
      nextPaydayDate: nextPaydayDate,
      expectedAmount: Value(expectedAmount),
      paydayBehavior: Value(enumToDb(paydayBehavior)),
      isPaydayAnchor: Value(isPaydayAnchor),
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }

  Future<void> update({
    required String id,
    required String name,
    required IncomeFrequency frequency,
    required DateTime nextPaydayDate,
    double? expectedAmount,
    required PaydayBehavior paydayBehavior,
  }) async {
    await _repo.updateById(
      id,
      RecurringIncomesCompanion(
        name: Value(name.trim()),
        frequency: Value(enumToDb(frequency)),
        nextPaydayDate: Value(nextPaydayDate),
        expectedAmount: Value(expectedAmount),
        paydayBehavior: Value(enumToDb(paydayBehavior)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) => _repo.deleteById(id);

  Future<void> setPaydayAnchor(String id) => _repo.setPaydayAnchor(id);

  Future<void> clearPaydayAnchor() => _repo.clearPaydayAnchor();

  Future<void> advancePayday(String id) async {
    final income = await _repo.getById(id);
    final freq = enumFromDb<IncomeFrequency>(
      income.frequency,
      IncomeFrequency.values,
    );
    final next = advanceByIncomeFrequency(income.nextPaydayDate, freq);
    await _repo.updateById(
      id,
      RecurringIncomesCompanion(
        nextPaydayDate: Value(next),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  static DateTime computeNextPayday(
    DateTime current,
    IncomeFrequency frequency,
  ) {
    return advanceByIncomeFrequency(current, frequency);
  }
}
