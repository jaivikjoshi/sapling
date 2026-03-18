import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/leko_database.dart';
import '../../data/repositories/daily_closeouts_repository.dart';
import '../../data/repositories_supabase/supabase_daily_closeouts_repository.dart';
import '../../domain/services/closeout_service.dart';
import 'allowance_providers.dart';
import 'auth_providers.dart';
import 'db_provider.dart';
import 'settings_providers.dart';

final dailyCloseoutsRepositoryProvider = Provider<DailyCloseoutsRepository>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return DriftDailyCloseoutsRepository(ref.watch(databaseProvider));
  }
  return SupabaseDailyCloseoutsRepository(
      ref.watch(supabaseClientProvider), userId);
});

final closeoutServiceProvider = Provider<CloseoutService>((ref) {
  return CloseoutService(
    ref.watch(dailyCloseoutsRepositoryProvider),
    ref.watch(allowanceEngineProvider),
  );
});

final closeoutsStreamProvider = StreamProvider<List<DailyCloseout>>((ref) {
  return ref.watch(dailyCloseoutsRepositoryProvider).watchAllOrderedByDateDesc();
});

final streakProvider = FutureProvider<StreakResult>((ref) async {
  final settings = ref.watch(settingsStreamProvider).valueOrNull;
  if (settings == null) return const StreakResult(currentStreak: 0, todayWithinBudget: false);
  final service = ref.watch(closeoutServiceProvider);
  return service.computeStreak(settings: settings);
});

final todayCloseoutProvider = FutureProvider<DailyCloseout?>((ref) async {
  final service = ref.watch(closeoutServiceProvider);
  return service.getCloseoutForDate(DateTime.now());
});
