import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/leko_database.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories_supabase/supabase_bills_repository.dart';
import '../../domain/services/bills_service.dart';
import 'auth_providers.dart';
import 'db_provider.dart';
import 'ledger_providers.dart';

final billsRepositoryProvider = Provider<BillsRepository>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return DriftBillsRepository(ref.watch(databaseProvider));
  }
  return SupabaseBillsRepository(ref.watch(supabaseClientProvider), userId);
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
