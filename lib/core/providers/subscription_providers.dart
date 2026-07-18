import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/monetization/revenuecat_subscription_service.dart';
import '../../domain/monetization/subscription_service.dart';
import 'auth_providers.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final service = RevenueCatSubscriptionService();
  final userId = ref.watch(currentUserProvider)?.id;
  service.configure(appUserId: userId).ignore();
  return service.canConfigure
      ? service
      : const UnconfiguredSubscriptionService();
});

final subscriptionStatusProvider = FutureProvider<SubscriptionStatus>((ref) {
  return ref.watch(subscriptionServiceProvider).status();
});

final subscriptionOffersProvider = FutureProvider<List<SubscriptionOffer>>((
  ref,
) {
  return ref.watch(subscriptionServiceProvider).offers();
});
