import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

abstract class GoalsRepository {
  Future<List<Goal>> getAll();
  Stream<List<Goal>> watchAll();
  Stream<List<Goal>> watchArchived();
  Future<Goal> getById(String id);
  Future<void> insert(GoalsCompanion companion);
  Future<void> updateById(String id, GoalsCompanion companion);
  Future<void> deleteById(String id);
}

class DriftGoalsRepository implements GoalsRepository {
  final SaplingDatabase _db;

  DriftGoalsRepository(this._db);

  @override
  Future<List<Goal>> getAll() {
    return (_db.select(_db.goals)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.priorityOrder)]))
        .get();
  }

  @override
  Stream<List<Goal>> watchAll() {
    return (_db.select(_db.goals)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.priorityOrder)]))
        .watch();
  }

  @override
  Stream<List<Goal>> watchArchived() {
    return (_db.select(_db.goals)
          ..where((t) => t.isArchived.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  @override
  Future<Goal> getById(String id) {
    return (_db.select(_db.goals)..where((t) => t.id.equals(id))).getSingle();
  }

  @override
  Future<void> insert(GoalsCompanion companion) {
    return _db.into(_db.goals).insert(companion);
  }

  @override
  Future<void> updateById(String id, GoalsCompanion companion) {
    return (_db.update(_db.goals)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  @override
  Future<void> deleteById(String id) {
    return (_db.delete(_db.goals)..where((t) => t.id.equals(id))).go();
  }
}
