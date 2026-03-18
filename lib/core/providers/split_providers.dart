import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/leko_database.dart';
import '../../data/repositories/persons_repository.dart';
import '../../data/repositories/split_entries_repository.dart';
import '../../data/repositories/split_shares_repository.dart';
import '../../data/repositories_supabase/supabase_persons_repository.dart';
import '../../data/repositories_supabase/supabase_split_entries_repository.dart';
import '../../data/repositories_supabase/supabase_split_shares_repository.dart';
import '../../domain/services/split_service.dart';
import 'auth_providers.dart';
import 'db_provider.dart';
import 'ledger_providers.dart';

final personsRepositoryProvider = Provider<PersonsRepository>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return DriftPersonsRepository(ref.watch(databaseProvider));
  }
  return SupabasePersonsRepository(ref.watch(supabaseClientProvider), userId);
});

final splitEntriesRepositoryProvider = Provider<SplitEntriesRepository>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return DriftSplitEntriesRepository(ref.watch(databaseProvider));
  }
  return SupabaseSplitEntriesRepository(
      ref.watch(supabaseClientProvider), userId);
});

final splitSharesRepositoryProvider = Provider<SplitSharesRepository>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return DriftSplitSharesRepository(ref.watch(databaseProvider));
  }
  return SupabaseSplitSharesRepository(ref.watch(supabaseClientProvider));
});

final splitServiceProvider = Provider<SplitService>((ref) {
  return SplitService(
    ref.watch(splitEntriesRepositoryProvider),
    ref.watch(splitSharesRepositoryProvider),
    ref.watch(transactionsRepositoryProvider),
    ref.watch(personsRepositoryProvider),
  );
});

final openSplitsStreamProvider =
    StreamProvider<List<SplitEntry>>((ref) {
  return ref.watch(splitServiceProvider).watchOpenSplits();
});

final openSplitsForPersonProvider =
    StreamProvider.family<List<SplitEntry>, String>((ref, personId) {
  return ref.watch(splitServiceProvider).watchOpenSplitsForPerson(personId);
});

final splitDetailProvider =
    FutureProvider.family<SplitEntry?, String>((ref, splitEntryId) {
  return ref.watch(splitServiceProvider).getSplitById(splitEntryId);
});

final personsListProvider = StreamProvider<List<Person>>((ref) {
  return ref.watch(splitServiceProvider).watchPersons();
});

final splitBalancesProvider =
    StreamProvider<Map<String, PersonBalance>>((ref) {
  return ref.watch(splitServiceProvider).watchBalancesByPerson();
});
