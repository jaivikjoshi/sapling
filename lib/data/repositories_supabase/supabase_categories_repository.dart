import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/leko_database.dart';
import '../repositories/categories_repository.dart';
import '../supabase/entity_mappers.dart';

class SupabaseCategoriesRepository implements CategoriesRepository {
  SupabaseCategoriesRepository(this._client, this._userId);

  final SupabaseClient _client;
  final String _userId;

  static const _pollInterval = Duration(seconds: 30);

  @override
  Stream<List<Category>> watchAll() async* {
    yield await getAll();
    await for (final _ in Stream.periodic(_pollInterval)) {
      yield await getAll();
    }
  }

  @override
  Future<List<Category>> getAll() async {
    final res = await _client
        .from('categories')
        .select()
        .order('is_system')
        .order('name');
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(categoryFromSupabase)
        .toList();
  }

  @override
  Future<Category> getById(String id) async {
    final res = await _client.from('categories').select().eq('id', id).maybeSingle();
    if (res == null) throw Exception('Category not found: $id');
    return categoryFromSupabase(res as Map<String, dynamic>);
  }

  @override
  Future<bool> nameExists(String name, {String? excludeId}) async {
    final res = await _client.from('categories').select('id').eq('name', name);
    final list = (res as List).cast<Map<String, dynamic>>();
    if (excludeId != null) {
      return list.any((r) => r['id'] != excludeId);
    }
    return list.isNotEmpty;
  }

  @override
  Future<void> insert(CategoriesCompanion companion) async {
    final c = _companionToCategory(companion);
    final map = categoryToSupabase(c);
    map['user_id'] = _userId;
    await _client.from('categories').insert(map);
  }

  @override
  Future<void> updateById(String id, CategoriesCompanion companion) async {
    final map = <String, dynamic>{};
    if (companion.name.present) map['name'] = companion.name.value;
    if (companion.defaultLabel.present) {
      map['default_label'] = companion.defaultLabel.value;
    }
    if (companion.isSystem.present) map['is_system'] = companion.isSystem.value;
    map['updated_at'] = DateTime.now().toIso8601String();
    if (map.length <= 1) return;
    await _client.from('categories').update(map).eq('id', id).eq('user_id', _userId);
  }

  @override
  Future<void> deleteById(String id) async {
    await _client.from('categories').delete().eq('id', id).eq('user_id', _userId);
  }

  Category _companionToCategory(CategoriesCompanion c) {
    final now = DateTime.now();
    return Category(
      id: c.id.value,
      name: c.name.value,
      defaultLabel: c.defaultLabel.present ? c.defaultLabel.value : 'green',
      isSystem: c.isSystem.present ? c.isSystem.value : false,
      createdAt: c.createdAt.present ? c.createdAt.value : now,
      updatedAt: c.updatedAt.present ? c.updatedAt.value : now,
    );
  }
}
