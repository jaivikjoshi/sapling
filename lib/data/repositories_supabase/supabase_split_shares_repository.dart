import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/leko_database.dart';
import '../repositories/split_shares_repository.dart';
import '../supabase/companion_mappers.dart';
import '../supabase/entity_mappers.dart';

class SupabaseSplitSharesRepository implements SplitSharesRepository {
  SupabaseSplitSharesRepository(this._client);

  final SupabaseClient _client;

  static const _pollInterval = Duration(seconds: 30);

  Stream<T> _pollStream<T>(Future<T> Function() fetch) async* {
    yield await fetch();
    await for (final _ in Stream.periodic(_pollInterval)) {
      yield await fetch();
    }
  }

  @override
  Future<List<SplitShare>> getBySplitEntryId(String splitEntryId) async {
    final res = await _client
        .from('split_shares')
        .select()
        .eq('split_entry_id', splitEntryId);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(splitShareFromSupabase)
        .toList();
  }

  @override
  Stream<List<SplitShare>> watchBySplitEntryId(String splitEntryId) {
    return _pollStream(() => getBySplitEntryId(splitEntryId));
  }

  @override
  Future<List<SplitShare>> getByPersonId(String personId) async {
    final res = await _client
        .from('split_shares')
        .select()
        .eq('person_id', personId);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(splitShareFromSupabase)
        .toList();
  }

  @override
  Future<void> insert(SplitSharesCompanion companion) async {
    final map = splitSharesCompanionToSupabase(companion);
    await _client.from('split_shares').insert(map);
  }

  @override
  Future<void> insertAll(List<SplitSharesCompanion> companions) async {
    final maps = companions.map((c) => splitSharesCompanionToSupabase(c)).toList();
    await _client.from('split_shares').insert(maps);
  }

  @override
  Future<void> deleteBySplitEntryId(String splitEntryId) async {
    await _client
        .from('split_shares')
        .delete()
        .eq('split_entry_id', splitEntryId);
  }

  @override
  Future<void> updateShareAmount(String id, double shareAmount) async {
    await _client
        .from('split_shares')
        .update({'share_amount': shareAmount})
        .eq('id', id);
  }
}
