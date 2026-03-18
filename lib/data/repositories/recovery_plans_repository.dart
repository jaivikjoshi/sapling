import 'package:drift/drift.dart';
import '../db/leko_database.dart';

abstract class RecoveryPlansRepository {
  Future<List<RecoveryPlan>> getAll();
  Future<RecoveryPlan?> getActive();
  Stream<RecoveryPlan?> watchActive();
  Future<void> insert(RecoveryPlansCompanion companion);
  Future<void> updateById(String id, RecoveryPlansCompanion companion);
  Future<void> cancelAll();
}

class DriftRecoveryPlansRepository implements RecoveryPlansRepository {
  final LekoDatabase _db;

  DriftRecoveryPlansRepository(this._db);

  @override
  Future<List<RecoveryPlan>> getAll() {
    return (_db.select(_db.recoveryPlans)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  @override
  Future<RecoveryPlan?> getActive() async {
    final rows = await (_db.select(_db.recoveryPlans)
          ..where((t) => t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Stream<RecoveryPlan?> watchActive() {
    return (_db.select(_db.recoveryPlans)
          ..where((t) => t.status.equals('active'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .watch()
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  @override
  Future<void> insert(RecoveryPlansCompanion companion) {
    return _db.into(_db.recoveryPlans).insert(companion);
  }

  @override
  Future<void> updateById(String id, RecoveryPlansCompanion companion) {
    return (_db.update(_db.recoveryPlans)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  @override
  Future<void> cancelAll() async {
    await (_db.update(_db.recoveryPlans)
          ..where((t) => t.status.equals('active')))
        .write(const RecoveryPlansCompanion(status: Value('canceled')));
  }
}
