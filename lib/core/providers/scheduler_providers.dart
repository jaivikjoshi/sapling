import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/closeout_notification_service.dart';
import '../../data/repositories/scheduler_metadata_repository.dart';
import '../../data/repositories_supabase/supabase_scheduler_metadata_repository.dart';
import 'auth_providers.dart';
import 'bills_providers.dart';
import 'db_provider.dart';
import 'ledger_providers.dart';
import 'recurring_income_providers.dart';
import 'settings_providers.dart';
import '../../domain/schedulers/cycle_boundary_watcher.dart';
import '../../domain/schedulers/notification_scheduler_impl.dart';
import '../../domain/schedulers/payday_auto_poster.dart';

final schedulerMetadataRepositoryProvider =
    Provider<SchedulerMetadataRepository>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return DriftSchedulerMetadataRepository(ref.watch(databaseProvider));
  }
  return SupabaseSchedulerMetadataRepository(
      ref.watch(supabaseClientProvider), userId);
});

final cycleBoundaryWatcherProvider = Provider<CycleBoundaryWatcher>((ref) {
  return CycleBoundaryWatcher(
    ref.watch(schedulerMetadataRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
    ref.watch(recurringIncomeRepositoryProvider),
  );
});

final paydayAutoPosterProvider = Provider<PaydayAutoPoster>((ref) {
  return PaydayAutoPoster(
    ref.watch(recurringIncomeRepositoryProvider),
    ref.watch(transactionsRepositoryProvider),
  );
});

final notificationSchedulerProvider = Provider<NotificationSchedulerImpl>((ref) {
  return NotificationSchedulerImpl(
    CloseoutNotificationService.instance,
    ref.watch(settingsRepositoryProvider),
    ref.watch(recurringIncomeRepositoryProvider),
    ref.watch(billsRepositoryProvider),
    ref.watch(schedulerMetadataRepositoryProvider),
  );
});

final schedulerLastRunAtProvider = FutureProvider<String?>((ref) async {
  return ref.watch(notificationSchedulerProvider).getLastRunAt();
});
