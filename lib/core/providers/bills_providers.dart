import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/sapling_database.dart';
import '../../data/repositories/bills_repository.dart';
import '../../domain/services/bills_service.dart';
import 'db_provider.dart';
import 'ledger_providers.dart';

final billsRepositoryProvider = Provider<BillsRepository>((ref) {
  return BillsRepository(ref.watch(databaseProvider));
});

final billsServiceProvider = Provider<BillsService>((ref) {
  return BillsService(
    ref.watch(billsRepositoryProvider),
    ref.watch(transactionsRepositoryProvider),
  );
});

final billsStreamProvider = StreamProvider<List<Bill>>((ref) {
  return ref.watch(billsServiceProvider).watchAll();
});

final upcomingBillsProvider = StreamProvider<List<Bill>>((ref) {
  return ref.watch(billsServiceProvider).watchUpcoming(days: 30);
});
