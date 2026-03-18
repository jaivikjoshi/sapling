import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/leko_database.dart';
import '../../data/repositories/recurring_income_repository.dart';
import '../../data/repositories_supabase/supabase_recurring_income_repository.dart';
import '../../domain/services/recurring_income_service.dart';
import 'auth_providers.dart';
import 'db_provider.dart';

final recurringIncomeRepositoryProvider =
    Provider<RecurringIncomeRepository>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return DriftRecurringIncomeRepository(ref.watch(databaseProvider));
  }
  return SupabaseRecurringIncomeRepository(
      ref.watch(supabaseClientProvider), userId);
});

final recurringIncomeServiceProvider =
    Provider<RecurringIncomeService>((ref) {
  return RecurringIncomeService(ref.watch(recurringIncomeRepositoryProvider));
});

final recurringIncomesProvider = StreamProvider<List<RecurringIncome>>((ref) {
  return ref.watch(recurringIncomeRepositoryProvider).watchAll();
});
