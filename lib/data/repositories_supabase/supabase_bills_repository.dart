import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/sapling_database.dart';
import '../repositories/bills_repository.dart';
import '../supabase/companion_mappers.dart';
import '../supabase/entity_mappers.dart';

class SupabaseBillsRepository implements BillsRepository {
  SupabaseBillsRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const _pollInterval = Duration(seconds: 30);

  Stream<T> _pollStream<T>(Future<T> Function() fetch) async* {
    yield await fetch();
    await for (final _ in Stream.periodic(_pollInterval)) {
      yield await fetch();
    }
  }

  @override
  Future<List<Bill>> getAll() async {
    final res = await _client
        .from('bills')
        .select()
        .eq('user_id', _userId)
        .order('next_due_date', ascending: true);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(billFromSupabase)
        .toList();
  }

  @override
  Stream<List<Bill>> watchAll() {
    return _pollStream(getAll);
  }

  @override
  Future<Bill> getById(String id) async {
    final res = await _client
        .from('bills')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (res == null) throw Exception('Bill not found: $id');
    return billFromSupabase(res as Map<String, dynamic>);
  }

  @override
  Future<void> insert(BillsCompanion companion) async {
    final map = billsCompanionToSupabase(companion, _userId);
    await _client.from('bills').insert(map);
  }

  @override
  Future<void> updateById(String id, BillsCompanion companion) async {
    final map = billsCompanionToSupabase(companion, _userId);
    map.remove('id');
    map.remove('user_id');
    map['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('bills').update(map).eq('id', id).eq('user_id', _userId);
  }

  @override
  Future<void> deleteById(String id) async {
    await _client.from('bills').delete().eq('id', id).eq('user_id', _userId);
  }

  @override
  Stream<List<Bill>> watchUpcoming({int days = 30}) {
    return _pollStream(() async {
      final now = DateTime.now();
      final cutoff = DateTime(now.year, now.month, now.day + days);
      final res = await _client
          .from('bills')
          .select()
          .eq('user_id', _userId)
          .lte('next_due_date', cutoff.toIso8601String())
          .order('next_due_date', ascending: true);
      return (res as List)
          .cast<Map<String, dynamic>>()
          .map(billFromSupabase)
          .toList();
    });
  }
}
