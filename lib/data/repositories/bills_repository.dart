import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

abstract class BillsRepository {
  Future<List<Bill>> getAll();
  Stream<List<Bill>> watchAll();
  Future<Bill> getById(String id);
  Future<void> insert(BillsCompanion companion);
  Future<void> updateById(String id, BillsCompanion companion);
  Future<void> deleteById(String id);
  Stream<List<Bill>> watchUpcoming({int days = 30});
}

class DriftBillsRepository implements BillsRepository {
  final SaplingDatabase _db;

  DriftBillsRepository(this._db);

  @override
  Future<List<Bill>> getAll() {
    return (_db.select(_db.bills)
          ..orderBy([(t) => OrderingTerm.asc(t.nextDueDate)]))
        .get();
  }

  @override
  Stream<List<Bill>> watchAll() {
    return (_db.select(_db.bills)
          ..orderBy([(t) => OrderingTerm.asc(t.nextDueDate)]))
        .watch();
  }

  @override
  Future<Bill> getById(String id) {
    return (_db.select(_db.bills)..where((t) => t.id.equals(id))).getSingle();
  }

  @override
  Future<void> insert(BillsCompanion companion) {
    return _db.into(_db.bills).insert(companion);
  }

  @override
  Future<void> updateById(String id, BillsCompanion companion) {
    return (_db.update(_db.bills)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  @override
  Future<void> deleteById(String id) {
    return (_db.delete(_db.bills)..where((t) => t.id.equals(id))).go();
  }

  @override
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
