import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/reports_service.dart';
import 'ledger_providers.dart';

final reportsServiceProvider = Provider<ReportsService>((ref) {
  return ReportsService(
    ref.watch(transactionsRepositoryProvider),
    ref.watch(categoriesRepositoryProvider),
  );
});
