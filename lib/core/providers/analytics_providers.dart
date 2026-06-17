import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/leko_analytics.dart';
import '../config/production_dart_defines.dart';

final lekoAnalyticsProvider = Provider<LekoAnalytics>((ref) {
  if (!ProductionDartDefines.analyticsEnabled) {
    return const NoopLekoAnalytics();
  }
  return const ProductionLekoAnalytics();
});
