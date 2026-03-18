import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/leko_database.dart';
import '../repositories/daily_closeouts_repository.dart';
import '../supabase/companion_mappers.dart';
import '../supabase/entity_mappers.dart';

class SupabaseDailyCloseoutsRepository implements DailyCloseoutsRepository {
  SupabaseDailyCloseoutsRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const _pollInterval = Duration(seconds: 30);

  String _dateToIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Stream<T> _pollStream<T>(Future<T> Function() fetch) async* {
    yield await fetch();
    await for (final _ in Stream.periodic(_pollInterval)) {
      yield await fetch();
    }
  }

  @override
  Future<void> insert(DailyCloseoutsCompanion companion) async {
    final map = dailyCloseoutsCompanionToSupabase(companion, _userId);
    await _client.from('daily_closeouts').insert(map);
  }

  @override
  Future<DailyCloseout?> getByDateBucket(DateTime dateBucket) async {
    final start = DateTime(dateBucket.year, dateBucket.month, dateBucket.day);
    final dateStr = _dateToIso(start);
    final res = await _client
        .from('daily_closeouts')
        .select()
        .eq('user_id', _userId)
        .eq('date', dateStr)
        .maybeSingle();
    return res == null
        ? null
        : dailyCloseoutFromSupabase(res as Map<String, dynamic>);
  }

  @override
  Future<List<DailyCloseout>> getAllOrderedByDateDesc() async {
    final res = await _client
        .from('daily_closeouts')
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(dailyCloseoutFromSupabase)
        .toList();
  }

  @override
  Stream<List<DailyCloseout>> watchAllOrderedByDateDesc() {
    return _pollStream(getAllOrderedByDateDesc);
  }

  @override
  Future<void> deleteById(String id) async {
    await _client
        .from('daily_closeouts')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
