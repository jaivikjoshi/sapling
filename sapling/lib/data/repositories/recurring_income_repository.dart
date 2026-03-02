import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

class RecurringIncomeRepository {
  final SaplingDatabase _db;

  RecurringIncomeRepository(this._db);

  Future<List<RecurringIncome>> getAll() {
    return (_db.select(_db.recurringIncomes)
          ..orderBy([(t) => OrderingTerm.asc(t.nextPaydayDate)]))
        .get();
  }

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

  Future<void> insert(RecurringIncomesCompanion companion) {
    return _db.into(_db.recurringIncomes).insert(companion);
  }

  Future<void> updateById(String id, RecurringIncomesCompanion companion) {
    return (_db.update(_db.recurringIncomes)
          ..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> deleteById(String id) {
    return (_db.delete(_db.recurringIncomes)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  Future<void> clearPaydayAnchor() async {
    await (_db.update(_db.recurringIncomes)
          ..where((t) => t.isPaydayAnchor.equals(true)))
        .write(
      const RecurringIncomesCompanion(isPaydayAnchor: Value(false)),
    );
  }

  Future<void> setPaydayAnchor(String id) async {
    await clearPaydayAnchor();
    await (_db.update(_db.recurringIncomes)
          ..where((t) => t.id.equals(id)))
        .write(const RecurringIncomesCompanion(isPaydayAnchor: Value(true)));
  }

  Future<RecurringIncome?> getAnchor() async {
    final results = await (_db.select(_db.recurringIncomes)
          ..where((t) => t.isPaydayAnchor.equals(true)))
        .get();
    return results.isEmpty ? null : results.first;
  }
}
