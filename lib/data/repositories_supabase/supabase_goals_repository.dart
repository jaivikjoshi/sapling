import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/leko_database.dart';
import '../repositories/goals_repository.dart';
import '../supabase/companion_mappers.dart';
import '../supabase/entity_mappers.dart';

class SupabaseGoalsRepository implements GoalsRepository {
  SupabaseGoalsRepository(this._client, this._userId);

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
  Future<List<Goal>> getAll() async {
    final res = await _client
        .from('goals')
        .select()
        .eq('user_id', _userId)
        .eq('is_archived', false)
        .order('priority_order', ascending: true);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(goalFromSupabase)
        .toList();
  }

  @override
  Stream<List<Goal>> watchAll() {
    return _pollStream(getAll);
  }

  @override
  Stream<List<Goal>> watchArchived() {
    return _pollStream(() async {
      final res = await _client
          .from('goals')
          .select()
          .eq('user_id', _userId)
          .eq('is_archived', true)
          .order('updated_at', ascending: false);
      return (res as List)
          .cast<Map<String, dynamic>>()
          .map(goalFromSupabase)
          .toList();
    });
  }

  @override
  Future<Goal> getById(String id) async {
    final res = await _client
        .from('goals')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (res == null) throw Exception('Goal not found: $id');
    return goalFromSupabase(res as Map<String, dynamic>);
  }

  @override
  Future<void> insert(GoalsCompanion companion) async {
    final map = goalsCompanionToSupabase(companion, _userId);
    await _client.from('goals').insert(map);
  }

  @override
  Future<void> updateById(String id, GoalsCompanion companion) async {
    final map = goalsCompanionToSupabase(companion, _userId);
    map.remove('id');
    map.remove('user_id');
    map['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('goals').update(map).eq('id', id).eq('user_id', _userId);
  }

  @override
  Future<void> deleteById(String id) async {
    await _client.from('goals').delete().eq('id', id).eq('user_id', _userId);
  }
}
