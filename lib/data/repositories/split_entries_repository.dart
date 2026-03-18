import 'package:drift/drift.dart';
import '../db/leko_database.dart';

abstract class SplitEntriesRepository {
  Future<List<SplitEntry>> getAll();
  Stream<List<SplitEntry>> watchAll();
  Future<SplitEntry?> getById(String id);
  Future<List<SplitEntry>> getOpen();
  Stream<List<SplitEntry>> watchOpen();
  Future<void> insert(SplitEntriesCompanion companion);
  Future<void> updateById(String id, SplitEntriesCompanion companion);
  Future<void> deleteById(String id);
  Future<SplitEntry?> getByLinkedExpenseId(String expenseId);
}

class DriftSplitEntriesRepository implements SplitEntriesRepository {
  final LekoDatabase _db;

  DriftSplitEntriesRepository(this._db);

  @override
  Future<List<SplitEntry>> getAll() {
    return (_db.select(_db.splitEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  @override
  Stream<List<SplitEntry>> watchAll() {
    return (_db.select(_db.splitEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  @override
  Future<SplitEntry?> getById(String id) async {
    return (_db.select(_db.splitEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<List<SplitEntry>> getOpen() {
    return (_db.select(_db.splitEntries)
          ..where((t) => t.status.equals('open'))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  @override
  Stream<List<SplitEntry>> watchOpen() {
    return (_db.select(_db.splitEntries)
          ..where((t) => t.status.equals('open'))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  @override
  Future<void> insert(SplitEntriesCompanion companion) {
    return _db.into(_db.splitEntries).insert(companion);
  }

  @override
  Future<void> updateById(String id, SplitEntriesCompanion companion) {
    return (_db.update(_db.splitEntries)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  @override
  Future<void> deleteById(String id) {
    return (_db.delete(_db.splitEntries)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<SplitEntry?> getByLinkedExpenseId(String expenseId) async {
    return (_db.select(_db.splitEntries)
          ..where((t) => t.linkToExpenseTransactionId.equals(expenseId)))
        .getSingleOrNull();
  }
}
