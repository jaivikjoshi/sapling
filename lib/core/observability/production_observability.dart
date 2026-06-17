import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/production_dart_defines.dart';

class ProductionObservability {
  const ProductionObservability._();

  static bool get isConfigured => ProductionDartDefines.sentryDsn.isNotEmpty;

  static Future<void> run(FutureOr<void> Function() appRunner) async {
    if (!isConfigured) {
      await appRunner();
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn = ProductionDartDefines.sentryDsn;
      options.environment = ProductionDartDefines.environment;
      if (ProductionDartDefines.release.isNotEmpty) {
        options.release = ProductionDartDefines.release;
      }
      options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
      options.attachScreenshot = false;
      options.sendDefaultPii = false;
    }, appRunner: appRunner);
  }

  static Future<void> reportError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    if (!isConfigured) {
      debugPrint('[Observability] $reason $error\n$stackTrace');
      return;
    }
    if (reason != null) {
      addBreadcrumb(category: 'error', message: reason);
    }
    await Sentry.captureException(error, stackTrace: stackTrace);
  }

  static void addBreadcrumb({
    required String category,
    required String message,
    Map<String, Object?> data = const {},
  }) {
    if (!isConfigured) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: category,
        message: message,
        data: data,
        level: SentryLevel.info,
      ),
    );
  }
}
