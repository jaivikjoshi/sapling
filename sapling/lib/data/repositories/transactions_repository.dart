import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

class TransactionsRepository {
  final SaplingDatabase _db;

  TransactionsRepository(this._db);

  Future<void> insert(TransactionsCompanion companion) {
    return _db.into(_db.transactions).insert(companion);
  }

  Future<void> updateById(String id, TransactionsCompanion companion) {
    return (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<void> deleteById(String id) {
    return (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<Transaction> getById(String id) {
    return (_db.select(_db.transactions)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<Transaction?> getByIdOrNull(String id) async {
    return (_db.select(_db.transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<Transaction>> watchAll({int? limit}) {
    final q = _db.select(_db.transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (limit != null) q.limit(limit);
    return q.watch();
  }

  Stream<List<Transaction>> watchByDateRange(DateTime start, DateTime end) {
    return (_db.select(_db.transactions)
          ..where((t) => t.date.isBiggerOrEqualValue(start) & t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) {
    return (_db.select(_db.transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  Future<List<Transaction>> getAll() {
    return _db.select(_db.transactions).get();
  }

  /// Balance as of end of day before [endExclusive] (all transactions with date < endExclusive).
  Future<double> computeBalanceUpTo(DateTime endExclusive) async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.date.isSmallerThanValue(endExclusive)))
        .get();
    double balance = 0;
    for (final row in rows) {
      switch (row.type) {
        case 'income':
          balance += row.amount;
        case 'expense':
          balance -= row.amount;
        case 'adjustment':
          balance += row.amount;
      }
    }
    return balance;
  }

  Future<double> computeBalance() async {
    final rows = await _db.select(_db.transactions).get();
    double balance = 0;
    for (final row in rows) {
      switch (row.type) {
        case 'income':
          balance += row.amount;
        case 'expense':
          balance -= row.amount;
        case 'adjustment':
          balance += row.amount;
      }
    }
    return balance;
  }

  Stream<double> watchBalance() {
    return _db.select(_db.transactions).watch().map((rows) {
      double balance = 0;
      for (final row in rows) {
        switch (row.type) {
          case 'income':
            balance += row.amount;
          case 'expense':
            balance -= row.amount;
          case 'adjustment':
            balance += row.amount;
        }
      }
      return balance;
    });
  }
}
