import 'package:flutter/foundation.dart';

import '../config/production_dart_defines.dart';
import '../observability/production_observability.dart';

enum LekoAnalyticsEvent {
  appOpened,
  onboardingStarted,
  onboardingCompleted,
  homeViewed,
  safeToSpendExplained,
  quickActionStarted,
  expenseCreated,
  incomeCreated,
  goalCreated,
  leafMessageSent,
  leafDraftConfirmed,
  importDraftApproved,
  importDraftRejected,
  paywallViewed,
  trialStarted,
  subscriptionPurchased,
  subscriptionRestored,
  subscriptionFailed,
}

extension LekoAnalyticsEventName on LekoAnalyticsEvent {
  String get eventName {
    return switch (this) {
      LekoAnalyticsEvent.appOpened => 'app_opened',
      LekoAnalyticsEvent.onboardingStarted => 'onboarding_started',
      LekoAnalyticsEvent.onboardingCompleted => 'onboarding_completed',
      LekoAnalyticsEvent.homeViewed => 'home_viewed',
      LekoAnalyticsEvent.safeToSpendExplained => 'safe_to_spend_explained',
      LekoAnalyticsEvent.quickActionStarted => 'quick_action_started',
      LekoAnalyticsEvent.expenseCreated => 'expense_created',
      LekoAnalyticsEvent.incomeCreated => 'income_created',
      LekoAnalyticsEvent.goalCreated => 'goal_created',
      LekoAnalyticsEvent.leafMessageSent => 'leaf_message_sent',
      LekoAnalyticsEvent.leafDraftConfirmed => 'leaf_draft_confirmed',
      LekoAnalyticsEvent.importDraftApproved => 'import_draft_approved',
      LekoAnalyticsEvent.importDraftRejected => 'import_draft_rejected',
      LekoAnalyticsEvent.paywallViewed => 'paywall_viewed',
      LekoAnalyticsEvent.trialStarted => 'trial_started',
      LekoAnalyticsEvent.subscriptionPurchased => 'subscription_purchased',
      LekoAnalyticsEvent.subscriptionRestored => 'subscription_restored',
      LekoAnalyticsEvent.subscriptionFailed => 'subscription_failed',
    };
  }
}

abstract interface class LekoAnalytics {
  void track(
    LekoAnalyticsEvent event, {
    Map<String, Object?> properties = const {},
  });
}

class ProductionLekoAnalytics implements LekoAnalytics {
  const ProductionLekoAnalytics();

  @override
  void track(
    LekoAnalyticsEvent event, {
    Map<String, Object?> properties = const {},
  }) {
    if (!ProductionDartDefines.analyticsEnabled) return;
    final safeProperties = _redact(properties);
    ProductionObservability.addBreadcrumb(
      category: 'analytics',
      message: event.eventName,
      data: safeProperties,
    );
    if (kDebugMode) {
      debugPrint('[Analytics] ${event.eventName} $safeProperties');
    }
  }

  Map<String, Object?> _redact(Map<String, Object?> properties) {
    return {
      for (final entry in properties.entries)
        if (!_blockedKeys.contains(entry.key.toLowerCase()))
          entry.key: entry.value,
    };
  }

  static const _blockedKeys = {
    'email',
    'name',
    'displayname',
    'merchant',
    'note',
    'transcript',
    'source',
  };
}

class NoopLekoAnalytics implements LekoAnalytics {
  const NoopLekoAnalytics();

  @override
  void track(
    LekoAnalyticsEvent event, {
    Map<String, Object?> properties = const {},
  }) {}
}
