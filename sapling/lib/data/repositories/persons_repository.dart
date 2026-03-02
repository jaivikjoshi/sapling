import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

class PersonsRepository {
  final SaplingDatabase _db;

  PersonsRepository(this._db);

  Future<List<Person>> getAll() {
    return (_db.select(_db.persons)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Stream<List<Person>> watchAll() {
    return (_db.select(_db.persons)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<Person?> getById(String id) async {
    return (_db.select(_db.persons)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insert(PersonsCompanion companion) {
    return _db.into(_db.persons).insert(companion);
  }

  Future<void> updateById(String id, PersonsCompanion companion) {
    return (_db.update(_db.persons)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> deleteById(String id) {
    return (_db.delete(_db.persons)..where((t) => t.id.equals(id))).go();
  }
}
