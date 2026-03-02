import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

class SplitSharesRepository {
  final SaplingDatabase _db;

  SplitSharesRepository(this._db);

  Future<List<SplitShare>> getBySplitEntryId(String splitEntryId) {
    return (_db.select(_db.splitShares)
          ..where((t) => t.splitEntryId.equals(splitEntryId)))
        .get();
  }

  Stream<List<SplitShare>> watchBySplitEntryId(String splitEntryId) {
    return (_db.select(_db.splitShares)
          ..where((t) => t.splitEntryId.equals(splitEntryId)))
        .watch();
  }

  Future<List<SplitShare>> getByPersonId(String personId) {
    return (_db.select(_db.splitShares)
          ..where((t) => t.personId.equals(personId)))
        .get();
  }

  Future<void> insert(SplitSharesCompanion companion) {
    return _db.into(_db.splitShares).insert(companion);
  }

  Future<void> insertAll(List<SplitSharesCompanion> companions) async {
    await _db.batch((b) {
      for (final c in companions) {
        b.insert(_db.splitShares, c);
      }
    });
  }

  Future<void> deleteBySplitEntryId(String splitEntryId) {
    return (_db.delete(_db.splitShares)
          ..where((t) => t.splitEntryId.equals(splitEntryId)))
        .go();
  }

  Future<void> updateShareAmount(String id, double shareAmount) {
    return (_db.update(_db.splitShares)..where((t) => t.id.equals(id)))
        .write(SplitSharesCompanion(shareAmount: Value(shareAmount)));
  }
}
