import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

class BillsRepository {
  final SaplingDatabase _db;

  BillsRepository(this._db);

  Future<List<Bill>> getAll() {
    return (_db.select(_db.bills)
          ..orderBy([(t) => OrderingTerm.asc(t.nextDueDate)]))
        .get();
  }

  Stream<List<Bill>> watchAll() {
    return (_db.select(_db.bills)
          ..orderBy([(t) => OrderingTerm.asc(t.nextDueDate)]))
        .watch();
  }

  Future<Bill> getById(String id) {
    return (_db.select(_db.bills)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> insert(BillsCompanion companion) {
    return _db.into(_db.bills).insert(companion);
  }

  Future<void> updateById(String id, BillsCompanion companion) {
    return (_db.update(_db.bills)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> deleteById(String id) {
    return (_db.delete(_db.bills)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<Bill>> watchUpcoming({int days = 30}) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day + days);
    return (_db.select(_db.bills)
          ..where(
              (t) => t.nextDueDate.isSmallerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.asc(t.nextDueDate)]))
        .watch();
  }
}
