import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/leko_database.dart';
import '../repositories/recovery_plans_repository.dart';
import '../supabase/companion_mappers.dart';
import '../supabase/entity_mappers.dart';

class SupabaseRecoveryPlansRepository implements RecoveryPlansRepository {
  SupabaseRecoveryPlansRepository(this._client, this._userId);

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
  Future<List<RecoveryPlan>> getAll() async {
    final res = await _client
        .from('recovery_plans')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(recoveryPlanFromSupabase)
        .toList();
  }

  @override
  Future<RecoveryPlan?> getActive() async {
    final res = await _client
        .from('recovery_plans')
        .select()
        .eq('user_id', _userId)
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(1);
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.isEmpty ? null : recoveryPlanFromSupabase(list.first);
  }

  @override
  Stream<RecoveryPlan?> watchActive() {
    return _pollStream(getActive);
  }

  @override
  Future<void> insert(RecoveryPlansCompanion companion) async {
    final map = recoveryPlansCompanionToSupabase(companion, _userId);
    await _client.from('recovery_plans').insert(map);
  }

  @override
  Future<void> updateById(String id, RecoveryPlansCompanion companion) async {
    final map = recoveryPlansCompanionToSupabase(companion, _userId);
    map.remove('id');
    map.remove('user_id');
    if (map.containsKey('created_at')) map.remove('created_at');
    await _client
        .from('recovery_plans')
        .update(map)
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<void> cancelAll() async {
    await _client
        .from('recovery_plans')
        .update({'status': 'canceled'})
        .eq('user_id', _userId)
        .eq('status', 'active');
  }
}
