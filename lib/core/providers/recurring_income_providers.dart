import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/sapling_database.dart';
import '../../data/repositories/recurring_income_repository.dart';
import '../../domain/services/recurring_income_service.dart';
import 'db_provider.dart';

final recurringIncomeRepositoryProvider =
    Provider<RecurringIncomeRepository>((ref) {
  return RecurringIncomeRepository(ref.watch(databaseProvider));
});

final recurringIncomeServiceProvider =
    Provider<RecurringIncomeService>((ref) {
  return RecurringIncomeService(ref.watch(recurringIncomeRepositoryProvider));
});

final recurringIncomesProvider = StreamProvider<List<RecurringIncome>>((ref) {
  return ref.watch(recurringIncomeRepositoryProvider).watchAll();
});
