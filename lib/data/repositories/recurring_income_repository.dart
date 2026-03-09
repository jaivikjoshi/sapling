import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

abstract class RecurringIncomeRepository {
  Future<List<RecurringIncome>> getAll();
  Stream<List<RecurringIncome>> watchAll();
  Future<RecurringIncome> getById(String id);
  Future<void> insert(RecurringIncomesCompanion companion);
  Future<void> updateById(String id, RecurringIncomesCompanion companion);
  Future<void> deleteById(String id);
  Future<void> clearPaydayAnchor();
  Future<void> setPaydayAnchor(String id);
  Future<RecurringIncome?> getAnchor();
}

class DriftRecurringIncomeRepository implements RecurringIncomeRepository {
  final SaplingDatabase _db;

  DriftRecurringIncomeRepository(this._db);

  @override
  Future<List<RecurringIncome>> getAll() {
    return (_db.select(_db.recurringIncomes)
          ..orderBy([(t) => OrderingTerm.asc(t.nextPaydayDate)]))
        .get();
  }

  @override
  Stream<List<RecurringIncome>> watchAll() {
    return (_db.select(_db.recurringIncomes)
          ..orderBy([(t) => OrderingTerm.asc(t.nextPaydayDate)]))
        .watch();
  }

  Future<RecurringIncome> getById(String id) {
    return (_db.select(_db.recurringIncomes)
          ..where((t) => t.id.equals(id)))
        .getSingle();
  }

  @override
  Future<void> insert(RecurringIncomesCompanion companion) {
    return _db.into(_db.recurringIncomes).insert(companion);
  }

  @override
  Future<void> updateById(String id, RecurringIncomesCompanion companion) {
    return (_db.update(_db.recurringIncomes)
          ..where((t) => t.id.equals(id)))
        .write(companion);
  }

  @override
  Future<void> deleteById(String id) {
    return (_db.delete(_db.recurringIncomes)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> clearPaydayAnchor() async {
    await (_db.update(_db.recurringIncomes)
          ..where((t) => t.isPaydayAnchor.equals(true)))
        .write(
      const RecurringIncomesCompanion(isPaydayAnchor: Value(false)),
    );
  }

  @override
  Future<void> setPaydayAnchor(String id) async {
    await clearPaydayAnchor();
    await (_db.update(_db.recurringIncomes)
          ..where((t) => t.id.equals(id)))
        .write(const RecurringIncomesCompanion(isPaydayAnchor: Value(true)));
  }

  @override
  Future<RecurringIncome?> getAnchor() async {
    final results = await (_db.select(_db.recurringIncomes)
          ..where((t) => t.isPaydayAnchor.equals(true)))
        .get();
    return results.isEmpty ? null : results.first;
  }
}
