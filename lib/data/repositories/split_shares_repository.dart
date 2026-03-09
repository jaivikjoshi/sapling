import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

abstract class SplitSharesRepository {
  Future<List<SplitShare>> getBySplitEntryId(String splitEntryId);
  Stream<List<SplitShare>> watchBySplitEntryId(String splitEntryId);
  Future<List<SplitShare>> getByPersonId(String personId);
  Future<void> insert(SplitSharesCompanion companion);
  Future<void> insertAll(List<SplitSharesCompanion> companions);
  Future<void> deleteBySplitEntryId(String splitEntryId);
  Future<void> updateShareAmount(String id, double shareAmount);
}

class DriftSplitSharesRepository implements SplitSharesRepository {
  final SaplingDatabase _db;

  DriftSplitSharesRepository(this._db);

  @override
  Future<List<SplitShare>> getBySplitEntryId(String splitEntryId) {
    return (_db.select(_db.splitShares)
          ..where((t) => t.splitEntryId.equals(splitEntryId)))
        .get();
  }

  @override
  Stream<List<SplitShare>> watchBySplitEntryId(String splitEntryId) {
    return (_db.select(_db.splitShares)
          ..where((t) => t.splitEntryId.equals(splitEntryId)))
        .watch();
  }

  @override
  Future<List<SplitShare>> getByPersonId(String personId) {
    return (_db.select(_db.splitShares)
          ..where((t) => t.personId.equals(personId)))
        .get();
  }

  @override
  Future<void> insert(SplitSharesCompanion companion) {
    return _db.into(_db.splitShares).insert(companion);
  }

  @override
  Future<void> insertAll(List<SplitSharesCompanion> companions) async {
    await _db.batch((b) {
      for (final c in companions) {
        b.insert(_db.splitShares, c);
      }
    });
  }

  @override
  Future<void> deleteBySplitEntryId(String splitEntryId) {
    return (_db.delete(_db.splitShares)
          ..where((t) => t.splitEntryId.equals(splitEntryId)))
        .go();
  }

  @override
  Future<void> updateShareAmount(String id, double shareAmount) {
    return (_db.update(_db.splitShares)..where((t) => t.id.equals(id)))
        .write(SplitSharesCompanion(shareAmount: Value(shareAmount)));
  }
}
