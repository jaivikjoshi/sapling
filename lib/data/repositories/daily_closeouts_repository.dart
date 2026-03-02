import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

class DailyCloseoutsRepository {
  final SaplingDatabase _db;

  DailyCloseoutsRepository(this._db);

  Future<void> insert(DailyCloseoutsCompanion companion) {
    return _db.into(_db.dailyCloseouts).insert(companion);
  }

  Future<DailyCloseout?> getByDateBucket(DateTime dateBucket) async {
    final start = DateTime(dateBucket.year, dateBucket.month, dateBucket.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.dailyCloseouts)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end)))
        .getSingleOrNull();
  }

  /// All closeouts ordered by date desc (for streak: most recent first).
  Future<List<DailyCloseout>> getAllOrderedByDateDesc() {
    return (_db.select(_db.dailyCloseouts)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Stream<List<DailyCloseout>> watchAllOrderedByDateDesc() {
    return (_db.select(_db.dailyCloseouts)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<void> deleteById(String id) {
    return (_db.delete(_db.dailyCloseouts)..where((t) => t.id.equals(id))).go();
  }
}
