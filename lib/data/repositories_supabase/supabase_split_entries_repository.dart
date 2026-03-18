import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/leko_database.dart';
import '../repositories/split_entries_repository.dart';
import '../supabase/companion_mappers.dart';
import '../supabase/entity_mappers.dart';

class SupabaseSplitEntriesRepository implements SplitEntriesRepository {
  SupabaseSplitEntriesRepository(this._client, this._userId);

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
  Future<List<SplitEntry>> getAll() async {
    final res = await _client
        .from('split_entries')
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(splitEntryFromSupabase)
        .toList();
  }

  @override
  Stream<List<SplitEntry>> watchAll() {
    return _pollStream(getAll);
  }

  @override
  Future<SplitEntry?> getById(String id) async {
    final res = await _client
        .from('split_entries')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    return res == null ? null : splitEntryFromSupabase(res as Map<String, dynamic>);
  }

  @override
  Future<List<SplitEntry>> getOpen() async {
    final res = await _client
        .from('split_entries')
        .select()
        .eq('user_id', _userId)
        .eq('status', 'open')
        .order('date', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(splitEntryFromSupabase)
        .toList();
  }

  @override
  Stream<List<SplitEntry>> watchOpen() {
    return _pollStream(getOpen);
  }

  @override
  Future<void> insert(SplitEntriesCompanion companion) async {
    final map = splitEntriesCompanionToSupabase(companion, _userId);
    await _client.from('split_entries').insert(map);
  }

  @override
  Future<void> updateById(String id, SplitEntriesCompanion companion) async {
    final map = splitEntriesCompanionToSupabase(companion, _userId);
    map.remove('id');
    map.remove('user_id');
    map['updated_at'] = DateTime.now().toIso8601String();
    await _client
        .from('split_entries')
        .update(map)
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<void> deleteById(String id) async {
    await _client
        .from('split_entries')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<SplitEntry?> getByLinkedExpenseId(String expenseId) async {
    final res = await _client
        .from('split_entries')
        .select()
        .eq('user_id', _userId)
        .eq('link_to_expense_transaction_id', expenseId)
        .maybeSingle();
    return res == null ? null : splitEntryFromSupabase(res as Map<String, dynamic>);
  }
}
