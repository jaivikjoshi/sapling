import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

class GoalsRepository {
  final SaplingDatabase _db;

  GoalsRepository(this._db);

  Future<List<Goal>> getAll() {
    return (_db.select(_db.goals)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.priorityOrder)]))
        .get();
  }

  Stream<List<Goal>> watchAll() {
    return (_db.select(_db.goals)
          ..where((t) => t.isArchived.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.priorityOrder)]))
        .watch();
  }

  Stream<List<Goal>> watchArchived() {
    return (_db.select(_db.goals)
          ..where((t) => t.isArchived.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<Goal> getById(String id) {
    return (_db.select(_db.goals)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> insert(GoalsCompanion companion) {
    return _db.into(_db.goals).insert(companion);
  }

  Future<void> updateById(String id, GoalsCompanion companion) {
    return (_db.update(_db.goals)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> deleteById(String id) {
    return (_db.delete(_db.goals)..where((t) => t.id.equals(id))).go();
  }
}
