import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/sapling_database.dart';
import '../repositories/recurring_income_repository.dart';
import '../supabase/companion_mappers.dart';
import '../supabase/entity_mappers.dart';

class SupabaseRecurringIncomeRepository implements RecurringIncomeRepository {
  SupabaseRecurringIncomeRepository(this._client, this._userId);

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
  Future<List<RecurringIncome>> getAll() async {
    final res = await _client
        .from('recurring_incomes')
        .select()
        .eq('user_id', _userId)
        .order('next_payday_date', ascending: true);
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(recurringIncomeFromSupabase)
        .toList();
  }

  @override
  Stream<List<RecurringIncome>> watchAll() {
    return _pollStream(getAll);
  }

  @override
  Future<RecurringIncome> getById(String id) async {
    final res = await _client
        .from('recurring_incomes')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (res == null) throw Exception('RecurringIncome not found: $id');
    return recurringIncomeFromSupabase(res as Map<String, dynamic>);
  }

  @override
  Future<void> insert(RecurringIncomesCompanion companion) async {
    final map = recurringIncomesCompanionToSupabase(companion, _userId);
    await _client.from('recurring_incomes').insert(map);
  }

  @override
  Future<void> updateById(String id, RecurringIncomesCompanion companion) async {
    final map = recurringIncomesCompanionToSupabase(companion, _userId);
    map.remove('id');
    map.remove('user_id');
    map['updated_at'] = DateTime.now().toIso8601String();
    await _client
        .from('recurring_incomes')
        .update(map)
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<void> deleteById(String id) async {
    await _client
        .from('recurring_incomes')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<void> clearPaydayAnchor() async {
    await _client
        .from('recurring_incomes')
        .update({'is_payday_anchor': false})
        .eq('user_id', _userId)
        .eq('is_payday_anchor', true);
  }

  @override
  Future<void> setPaydayAnchor(String id) async {
    await clearPaydayAnchor();
    await _client
        .from('recurring_incomes')
        .update({'is_payday_anchor': true})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<RecurringIncome?> getAnchor() async {
    final res = await _client
        .from('recurring_incomes')
        .select()
        .eq('user_id', _userId)
        .eq('is_payday_anchor', true);
    final list = (res as List).cast<Map<String, dynamic>>();
    return list.isEmpty ? null : recurringIncomeFromSupabase(list.first);
  }
}
