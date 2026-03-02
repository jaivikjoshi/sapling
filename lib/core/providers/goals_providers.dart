import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/sapling_database.dart';
import '../../data/repositories/goals_repository.dart';
import '../../domain/services/goals_service.dart';
import 'db_provider.dart';
import 'settings_providers.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository(ref.watch(databaseProvider));
});

final goalsServiceProvider = Provider<GoalsService>((ref) {
  return GoalsService(
    ref.watch(goalsRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
  );
});

final goalsStreamProvider = StreamProvider<List<Goal>>((ref) {
  return ref.watch(goalsServiceProvider).watchAll();
});

final archivedGoalsProvider = StreamProvider<List<Goal>>((ref) {
  return ref.watch(goalsServiceProvider).watchArchived();
});
