import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

abstract class DailyCloseoutsRepository {
  Future<void> insert(DailyCloseoutsCompanion companion);
  Future<DailyCloseout?> getByDateBucket(DateTime dateBucket);
  Future<List<DailyCloseout>> getAllOrderedByDateDesc();
  Stream<List<DailyCloseout>> watchAllOrderedByDateDesc();
  Future<void> deleteById(String id);
}

class DriftDailyCloseoutsRepository implements DailyCloseoutsRepository {
  final SaplingDatabase _db;

  DriftDailyCloseoutsRepository(this._db);

  @override
  Future<void> insert(DailyCloseoutsCompanion companion) {
    return _db.into(_db.dailyCloseouts).insert(companion);
  }

  @override
  Future<DailyCloseout?> getByDateBucket(DateTime dateBucket) async {
    final start = DateTime(dateBucket.year, dateBucket.month, dateBucket.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.dailyCloseouts)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end)))
        .getSingleOrNull();
  }

  /// All closeouts ordered by date desc (for streak: most recent first).
  @override
  Future<List<DailyCloseout>> getAllOrderedByDateDesc() {
    return (_db.select(_db.dailyCloseouts)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  @override
  Stream<List<DailyCloseout>> watchAllOrderedByDateDesc() {
    return (_db.select(_db.dailyCloseouts)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  @override
  Future<void> deleteById(String id) {
    return (_db.delete(_db.dailyCloseouts)..where((t) => t.id.equals(id))).go();
  }
}
