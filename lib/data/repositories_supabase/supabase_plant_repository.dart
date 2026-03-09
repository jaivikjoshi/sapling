import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/plant_state.dart';
import '../repositories/plant_repository.dart';

/// Supabase-backed plant state repository.
/// One row per user in the `plant_states` table.
class SupabasePlantRepository implements PlantRepository {
  SupabasePlantRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const _table = 'plant_states';
  static const _pollInterval = Duration(seconds: 30);

  @override
  Future<PlantState?> get() async {
    final res = await _client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .maybeSingle();
    if (res == null) return null;
    return PlantState.fromJson(res);
  }

  @override
  Future<void> upsert(PlantState state) async {
    final map = state.toJson();
    map['user_id'] = _userId;
    map['updated_at'] = DateTime.now().toIso8601String();
    await _client.from(_table).upsert(map, onConflict: 'user_id');
  }

  @override
  Stream<PlantState?> watch() async* {
    // Emit the current state immediately.
    yield await get();
    // Then poll periodically (Supabase Realtime is an option for future).
    await for (final _ in Stream.periodic(_pollInterval)) {
      yield await get();
    }
  }
}
