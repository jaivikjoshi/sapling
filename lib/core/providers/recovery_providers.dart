import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/sapling_database.dart';
import '../../data/repositories/recovery_plans_repository.dart';
import '../../domain/services/overspend_detector.dart';
import '../../domain/services/recovery_plan_service.dart';
import 'allowance_providers.dart';
import 'db_provider.dart';
import 'ledger_providers.dart';

final recoveryPlansRepositoryProvider =
    Provider<RecoveryPlansRepository>((ref) {
  return RecoveryPlansRepository(ref.watch(databaseProvider));
});

final recoveryPlanServiceProvider = Provider<RecoveryPlanService>((ref) {
  return RecoveryPlanService(ref.watch(recoveryPlansRepositoryProvider));
});

final overspendDetectorProvider = Provider<OverspendDetector>((ref) {
  return OverspendDetector(
    ref.watch(allowanceEngineProvider),
    ref.watch(transactionsRepositoryProvider),
  );
});

final activeRecoveryPlanProvider = StreamProvider<RecoveryPlan?>((ref) {
  return ref.watch(recoveryPlanServiceProvider).watchActive();
});
