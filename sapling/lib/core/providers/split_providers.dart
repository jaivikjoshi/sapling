import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/sapling_database.dart';
import '../../data/repositories/persons_repository.dart';
import '../../data/repositories/split_entries_repository.dart';
import '../../data/repositories/split_shares_repository.dart';
import '../../domain/services/split_service.dart';
import 'db_provider.dart';
import 'ledger_providers.dart';

final personsRepositoryProvider = Provider<PersonsRepository>((ref) {
  return PersonsRepository(ref.watch(databaseProvider));
});

final splitEntriesRepositoryProvider = Provider<SplitEntriesRepository>((ref) {
  return SplitEntriesRepository(ref.watch(databaseProvider));
});

final splitSharesRepositoryProvider = Provider<SplitSharesRepository>((ref) {
  return SplitSharesRepository(ref.watch(databaseProvider));
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
