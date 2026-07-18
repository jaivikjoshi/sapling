import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/leko_analytics.dart';
import '../../core/providers/analytics_providers.dart';
import '../../core/providers/subscription_providers.dart';
import '../../domain/monetization/subscription_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _busyOfferId;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(lekoAnalyticsProvider)
          .track(LekoAnalyticsEvent.paywallViewed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(subscriptionStatusProvider);
    final offers = ref.watch(subscriptionOffersProvider);

    return Scaffold(
      backgroundColor: _PaywallPalette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _PaywallPalette.textPrimary,
        title: const Text('Leko Premium'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          children: [
            const _HeroCard(),
            const SizedBox(height: 16),
            status.when(
              data:
                  (value) => _StatusBanner(
                    configured: value.isConfigured,
                    premium: value.isPremium,
                    message: value.message,
                  ),
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error:
                  (error, _) => _StatusBanner(
                    configured: false,
                    premium: false,
                    message: 'Subscription status could not load.',
                  ),
            ),
            const SizedBox(height: 16),
            const _TierComparison(),
            const SizedBox(height: 18),
            offers.when(
              data:
                  (items) => Column(
                    children: [
                      for (final offer in items) ...[
                        _OfferCard(
                          offer: offer,
                          busy: _busyOfferId == offer.id,
                          onTap: () => _purchase(offer),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error:
                  (_, __) => const _StatusBanner(
                    configured: false,
                    premium: false,
                    message: 'Offers could not load right now.',
                  ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busyOfferId == 'restore' ? null : _restore,
              child:
                  _busyOfferId == 'restore'
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Restore purchases'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Subscriptions are handled by the App Store or Play Store through RevenueCat. Leko does not store payment card details.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _PaywallPalette.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase(SubscriptionOffer offer) async {
    setState(() => _busyOfferId = offer.id);
    try {
      final result = await ref
          .read(subscriptionServiceProvider)
          .purchase(offer.id);
      ref
          .read(lekoAnalyticsProvider)
          .track(
            result.isPremium
                ? LekoAnalyticsEvent.subscriptionPurchased
                : LekoAnalyticsEvent.subscriptionFailed,
            properties: {'offer_period': offer.period},
          );
      _showSnack(result.message);
      ref.invalidate(subscriptionStatusProvider);
    } finally {
      if (mounted) setState(() => _busyOfferId = null);
    }
  }

  Future<void> _restore() async {
    setState(() => _busyOfferId = 'restore');
    try {
      final result = await ref.read(subscriptionServiceProvider).restore();
      ref
          .read(lekoAnalyticsProvider)
          .track(
            LekoAnalyticsEvent.subscriptionRestored,
            properties: {'is_premium': result.isPremium},
          );
      _showSnack(result.message);
      ref.invalidate(subscriptionStatusProvider);
    } finally {
      if (mounted) setState(() => _busyOfferId = null);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _PaywallPalette.navy,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
          SizedBox(height: 18),
          Text(
            'Make Leko automatic when you are ready',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Premium is for bank review, receipt parsing, voice input, advanced reports, and unlimited Leaf guidance.',
            style: TextStyle(
              color: Color(0xCCDDE7EA),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.configured,
    required this.premium,
    this.message,
  });

  final bool configured;
  final bool premium;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text =
        premium
            ? 'Premium is active'
            : configured
            ? 'Premium checkout is ready'
            : message ?? 'RevenueCat is not configured for this build yet';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: premium ? const Color(0xFFEAF7EF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E9F0)),
      ),
      child: Row(
        children: [
          Icon(
            premium
                ? Icons.verified_rounded
                : configured
                ? Icons.lock_open_rounded
                : Icons.construction_rounded,
            color: premium ? const Color(0xFF2F7D4A) : _PaywallPalette.navy,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _PaywallPalette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierComparison extends StatelessWidget {
  const _TierComparison();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4E9F0)),
      ),
      child: const Column(
        children: [
          _FeatureRow(
            label: 'Manual tracking and daily safe-to-spend',
            free: true,
          ),
          _FeatureRow(label: 'Basic goals and reports', free: true),
          _FeatureRow(label: 'Unlimited Leaf assistant messages', free: false),
          _FeatureRow(
            label: 'Bank, receipt, notification, and voice review',
            free: false,
          ),
          _FeatureRow(
            label: 'Forecasts, anomalies, and subscription drift',
            free: false,
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label, required this.free});

  final String label;
  final bool free;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(
            free
                ? Icons.check_circle_outline_rounded
                : Icons.workspace_premium_rounded,
            color: free ? const Color(0xFF5E7D72) : _PaywallPalette.navy,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _PaywallPalette.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.busy,
    required this.onTap,
  });

  final SubscriptionOffer offer;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD8E0EA), width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
                    style: const TextStyle(
                      color: _PaywallPalette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.description,
                    style: const TextStyle(
                      color: _PaywallPalette.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            busy
                ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      offer.price,
                      style: const TextStyle(
                        color: _PaywallPalette.navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      offer.period,
                      style: const TextStyle(
                        color: _PaywallPalette.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}

abstract final class _PaywallPalette {
  static const background = Color(0xFFF5F7FB);
  static const navy = Color(0xFF132440);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
}
