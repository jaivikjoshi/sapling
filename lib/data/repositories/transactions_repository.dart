import 'package:drift/drift.dart';

import '../db/sapling_database.dart';

/// Interface for transactions repository (Drift or Supabase implementation).
abstract class TransactionsRepository {
  Future<void> insert(Transaction t);
  Future<void> updateById(String id, Transaction t);
  Future<void> deleteById(String id);
  Future<Transaction> getById(String id);
  Future<Transaction?> getByIdOrNull(String id);
  Stream<List<Transaction>> watchAll({int? limit});
  Stream<List<Transaction>> watchByDateRange(DateTime start, DateTime end);
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end);
  Future<List<Transaction>> getAll();
  Future<double> computeBalanceUpTo(DateTime endExclusive);
  Future<double> computeBalance();
  Stream<double> watchBalance();
}

class DriftTransactionsRepository implements TransactionsRepository {
  final SaplingDatabase _db;

  DriftTransactionsRepository(this._db);

  @override
  Future<void> insert(Transaction t) {
    return _db.into(_db.transactions).insert(t.toCompanion(true));
  }

  @override
  Future<void> updateById(String id, Transaction t) {
    return (_db.update(_db.transactions)..where((row) => row.id.equals(id)))
        .write(t.toCompanion(true));
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
