import 'package:drift/drift.dart';

import '../db/leko_database.dart';

abstract class SchedulerMetadataRepository {
  Future<String?> get(String key);
  Future<void> set(String key, String value);
}

class DriftSchedulerMetadataRepository implements SchedulerMetadataRepository {
  final LekoDatabase _db;

  DriftSchedulerMetadataRepository(this._db);

  @override
  Future<String?> get(String key) async {
    final row = await (_db.select(_db.schedulerMetadata)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> set(String key, String value) async {
    final existing = await (_db.select(_db.schedulerMetadata)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.schedulerMetadata)
            ..where((t) => t.key.equals(key)))
          .write(SchedulerMetadataCompanion(value: Value(value)));
    } else {
      await _db.into(_db.schedulerMetadata).insert(
            SchedulerMetadataCompanion.insert(key: key, value: value),
          );
    }
  }
}
