import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/sapling_database.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../domain/services/ledger_service.dart';
import 'db_provider.dart';

final transactionsRepositoryProvider =
    Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(ref.watch(databaseProvider));
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(databaseProvider));
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
