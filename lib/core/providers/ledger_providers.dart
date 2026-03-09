import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/sapling_database.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories_supabase/supabase_categories_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../data/repositories_supabase/supabase_transactions_repository.dart';
import '../../domain/services/ledger_service.dart';
import 'auth_providers.dart';
import 'db_provider.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return DriftTransactionsRepository(ref.watch(databaseProvider));
  }
  return SupabaseTransactionsRepository(client, userId);
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return DriftCategoriesRepository(ref.watch(databaseProvider));
  }
  return SupabaseCategoriesRepository(
    ref.watch(supabaseClientProvider),
    userId,
  );
});

final ledgerServiceProvider = Provider<LedgerService>((ref) {
  return LedgerService(ref.watch(transactionsRepositoryProvider));
});

final balanceStreamProvider = StreamProvider<double>((ref) {
  return ref.watch(ledgerServiceProvider).watchBalance();
});

final recentTransactionsProvider =
    StreamProvider<List<Transaction>>((ref) {
  return ref.watch(ledgerServiceProvider).watchRecent(limit: 50);
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).watchAll();
});
