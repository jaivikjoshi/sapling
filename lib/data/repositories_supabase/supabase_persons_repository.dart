import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/sapling_database.dart';
import '../repositories/persons_repository.dart';
import '../supabase/companion_mappers.dart';
import '../supabase/entity_mappers.dart';

class SupabasePersonsRepository implements PersonsRepository {
  SupabasePersonsRepository(this._client, this._userId);

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
  Future<List<Person>> getAll() async {
    final res = await _client
        .from('persons')
        .select()
        .eq('user_id', _userId)
        .order('name', ascending: true);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(personFromSupabase)
        .toList();
  }

  @override
  Stream<List<Person>> watchAll() {
    return _pollStream(getAll);
  }

  @override
  Future<Person?> getById(String id) async {
    final res = await _client
        .from('persons')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    return res == null ? null : personFromSupabase(res as Map<String, dynamic>);
  }

  @override
  Future<void> insert(PersonsCompanion companion) async {
    final map = personsCompanionToSupabase(companion, _userId);
    await _client.from('persons').insert(map);
  }

  @override
  Future<void> updateById(String id, PersonsCompanion companion) async {
    final map = personsCompanionToSupabase(companion, _userId);
    map.remove('id');
    map.remove('user_id');
    map['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('persons').update(map).eq('id', id).eq('user_id', _userId);
  }

  @override
  Future<void> deleteById(String id) async {
    await _client.from('persons').delete().eq('id', id).eq('user_id', _userId);
  }
}
