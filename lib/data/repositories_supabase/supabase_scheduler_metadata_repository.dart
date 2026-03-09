import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/scheduler_metadata_repository.dart';

class SupabaseSchedulerMetadataRepository implements SchedulerMetadataRepository {
  SupabaseSchedulerMetadataRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  @override
  Future<String?> get(String key) async {
    final res = await _client
        .from('scheduler_metadata')
        .select('value')
        .eq('key', key)
        .eq('user_id', _userId)
        .maybeSingle();
    return res == null ? null : (res as Map<String, dynamic>)['value'] as String?;
  }

  @override
  Future<void> set(String key, String value) async {
    await _client.from('scheduler_metadata').upsert(
      {
        'key': key,
        'user_id': _userId,
        'value': value,
      },
      onConflict: 'key,user_id',
    );
  }
}
