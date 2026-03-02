import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

class RecoveryPlansRepository {
  final SaplingDatabase _db;

  RecoveryPlansRepository(this._db);

  Future<List<RecoveryPlan>> getAll() {
    return (_db.select(_db.recoveryPlans)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<RecoveryPlan?> getActive() async {
    final rows = await (_db.select(_db.recoveryPlans)
          ..where((t) => t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  Stream<RecoveryPlan?> watchActive() {
    return (_db.select(_db.recoveryPlans)
          ..where((t) => t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .watch()
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  Future<void> insert(RecoveryPlansCompanion companion) {
    return _db.into(_db.recoveryPlans).insert(companion);
  }

  Future<void> updateById(String id, RecoveryPlansCompanion companion) {
    return (_db.update(_db.recoveryPlans)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> cancelAll() async {
    await (_db.update(_db.recoveryPlans)
          ..where((t) => t.status.equals('active')))
        .write(const RecoveryPlansCompanion(status: Value('canceled')));
  }
}
