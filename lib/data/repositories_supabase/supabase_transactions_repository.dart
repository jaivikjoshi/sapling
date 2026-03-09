import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/sapling_database.dart';
import '../repositories/transactions_repository.dart';
import '../supabase/entity_mappers.dart';

/// Supabase-backed implementation of transactions repository.
/// RLS scopes by user_id; pass current user id from auth.
class SupabaseTransactionsRepository implements TransactionsRepository {
  SupabaseTransactionsRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const _pollInterval = Duration(seconds: 30);

  Future<void> insert(Transaction t) async {
    final map = transactionToSupabase(t);
    map['user_id'] = _userId;
    await _client.from('transactions').insert(map);
  }

  Future<void> updateById(String id, Transaction t) async {
    final map = transactionToSupabase(t);
    map.remove('id');
    map.remove('user_id');
    map['updated_at'] = DateTime.now().toIso8601String();
    await _client
        .from('transactions')
        .update(map)
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> deleteById(String id) async {
    await _client
        .from('transactions')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<Transaction> getById(String id) async {
    final res = await _client
        .from('transactions')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (res == null) throw Exception('Transaction not found: $id');
    return transactionFromSupabase(res as Map<String, dynamic>);
  }

  Future<Transaction?> getByIdOrNull(String id) async {
    final res = await _client
        .from('transactions')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (res == null) return null;
    return transactionFromSupabase(res as Map<String, dynamic>);
  }

  Stream<List<Transaction>> watchAll({int? limit}) {
    return _pollStream(() async {
      var query = _client
          .from('transactions')
          .select()
          .eq('user_id', _userId)
          .order('date', ascending: false);
      if (limit != null) query = query.limit(limit);
      final res = await query;
      return (res as List)
          .cast<Map<String, dynamic>>()
          .map(transactionFromSupabase)
          .toList();
    });
  }

  Stream<List<Transaction>> watchByDateRange(DateTime start, DateTime end) {
    return _pollStream(() async {
      final res = await _client
          .from('transactions')
          .select()
          .eq('user_id', _userId)
          .gte('date', start.toIso8601String())
          .lt('date', end.toIso8601String())
          .order('date', ascending: false);
      return (res as List)
          .cast<Map<String, dynamic>>()
          .map(transactionFromSupabase)
          .toList();
    });
  }

  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) async {
    final res = await _client
        .from('transactions')
        .select()
        .eq('user_id', _userId)
        .gte('date', start.toIso8601String())
        .lt('date', end.toIso8601String())
        .order('date', ascending: true);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(transactionFromSupabase)
        .toList();
  }

  Future<List<Transaction>> getAll() async {
    final res = await _client
        .from('transactions')
        .select()
        .eq('user_id', _userId);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(transactionFromSupabase)
        .toList();
  }

  Future<double> computeBalanceUpTo(DateTime endExclusive) async {
    final res = await _client
        .from('transactions')
        .select()
        .eq('user_id', _userId)
        .lt('date', endExclusive.toIso8601String());
    return _computeBalanceFromRows((res as List).cast<Map<String, dynamic>>());
  }

  Future<double> computeBalance() async {
    final res = await _client
        .from('transactions')
        .select()
        .eq('user_id', _userId);
    return _computeBalanceFromRows((res as List).cast<Map<String, dynamic>>());
  }

  double _computeBalanceFromRows(List<Map<String, dynamic>> rows) {
    double balance = 0;
    for (final row in rows) {
      final t = transactionFromSupabase(row);
      switch (t.type) {
        case 'income':
          balance += t.amount;
        case 'expense':
          balance -= t.amount;
        case 'adjustment':
          balance += t.amount;
      }
    }
    return balance;
  }

  Stream<double> watchBalance() {
    return _pollStream(() => computeBalance());
  }

  Stream<T> _pollStream<T>(Future<T> Function() fetch) async* {
    yield await fetch();
    await for (final _ in Stream.periodic(_pollInterval)) {
      yield await fetch();
    }
  }
}
