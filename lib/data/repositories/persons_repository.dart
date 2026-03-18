import 'package:drift/drift.dart';
import '../db/leko_database.dart';

abstract class PersonsRepository {
  Future<List<Person>> getAll();
  Stream<List<Person>> watchAll();
  Future<Person?> getById(String id);
  Future<void> insert(PersonsCompanion companion);
  Future<void> updateById(String id, PersonsCompanion companion);
  Future<void> deleteById(String id);
}

class DriftPersonsRepository implements PersonsRepository {
  final LekoDatabase _db;

  DriftPersonsRepository(this._db);

  @override
  Future<List<Person>> getAll() {
    return (_db.select(_db.persons)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  @override
  Stream<List<Person>> watchAll() {
    return (_db.select(_db.persons)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  @override
  Future<Person?> getById(String id) async {
    return (_db.select(_db.persons)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  @override
  Future<void> insert(PersonsCompanion companion) {
    return _db.into(_db.persons).insert(companion);
  }

  @override
  Future<void> updateById(String id, PersonsCompanion companion) {
    return (_db.update(_db.persons)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  @override
  Future<void> deleteById(String id) {
    return (_db.delete(_db.persons)..where((t) => t.id.equals(id))).go();
  }
}
