import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

class SplitEntriesRepository {
  final SaplingDatabase _db;

  SplitEntriesRepository(this._db);

  Future<List<SplitEntry>> getAll() {
    return (_db.select(_db.splitEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Stream<List<SplitEntry>> watchAll() {
    return (_db.select(_db.splitEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<SplitEntry?> getById(String id) async {
    return (_db.select(_db.splitEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<SplitEntry>> getOpen() {
    return (_db.select(_db.splitEntries)
          ..where((t) => t.status.equals('open'))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Stream<List<SplitEntry>> watchOpen() {
    return (_db.select(_db.splitEntries)
          ..where((t) => t.status.equals('open'))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<void> insert(SplitEntriesCompanion companion) {
    return _db.into(_db.splitEntries).insert(companion);
  }

  Future<void> updateById(String id, SplitEntriesCompanion companion) {
    return (_db.update(_db.splitEntries)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> deleteById(String id) {
    return (_db.delete(_db.splitEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<SplitEntry?> getByLinkedExpenseId(String expenseId) async {
    return (_db.select(_db.splitEntries)
          ..where((t) => t.linkToExpenseTransactionId.equals(expenseId)))
        .getSingleOrNull();
  }
}
