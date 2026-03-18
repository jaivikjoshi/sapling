import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/leko_database.dart';
import '../../data/repositories/goals_repository.dart';
import '../../data/repositories_supabase/supabase_goals_repository.dart';
import '../../domain/services/goals_service.dart';
import 'auth_providers.dart';
import 'db_provider.dart';
import 'settings_providers.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return DriftGoalsRepository(ref.watch(databaseProvider));
  }
  return SupabaseGoalsRepository(ref.watch(supabaseClientProvider), userId);
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
