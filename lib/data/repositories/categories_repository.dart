import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

class CategoriesRepository {
  final SaplingDatabase _db;

  CategoriesRepository(this._db);

  Stream<List<Category>> watchAll() {
    return (_db.select(_db.categories)
          ..orderBy([
            (t) => OrderingTerm.asc(t.isSystem),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  Future<List<Category>> getAll() {
    return _db.select(_db.categories).get();
  }

  Future<Category> getById(String id) {
    return (_db.select(_db.categories)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<bool> nameExists(String name, {String? excludeId}) async {
    final q = _db.select(_db.categories)
      ..where((t) => t.name.equals(name));
    final results = await q.get();
    if (excludeId != null) {
      return results.any((c) => c.id != excludeId);
    }
    return results.isNotEmpty;
  }

  Future<void> insert(CategoriesCompanion companion) {
    return _db.into(_db.categories).insert(companion);
  }

  Future<void> updateById(String id, CategoriesCompanion companion) {
    return (_db.update(_db.categories)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> deleteById(String id) {
    return (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
  }
}
