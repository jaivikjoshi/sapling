abstract interface class SubscriptionService {
  Future<SubscriptionStatus> status();

  Future<List<SubscriptionOffer>> offers();

  Future<SubscriptionPurchaseResult> purchase(String offerId);

  Future<SubscriptionPurchaseResult> restore();
}

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.isConfigured,
    required this.isPremium,
    this.managementUrl,
    this.message,
  });

  final bool isConfigured;
  final bool isPremium;
  final Uri? managementUrl;
  final String? message;
}

class SubscriptionOffer {
  const SubscriptionOffer({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    required this.description,
  });

  final String id;
  final String title;
  final String price;
  final String period;
  final String description;
}

class SubscriptionPurchaseResult {
  const SubscriptionPurchaseResult({
    required this.isPremium,
    required this.message,
  });

  final bool isPremium;
  final String message;
}

class UnconfiguredSubscriptionService implements SubscriptionService {
  const UnconfiguredSubscriptionService();

  @override
  Future<List<SubscriptionOffer>> offers() async {
    return const [
      SubscriptionOffer(
        id: 'leko_premium_monthly_placeholder',
        title: 'Leko Premium Monthly',
        price: '\$4.99',
        period: 'month',
        description: 'Unlimited Leaf, imports, receipt parsing, and reports.',
      ),
      SubscriptionOffer(
        id: 'leko_premium_annual_placeholder',
        title: 'Leko Premium Annual',
        price: '\$39.99',
        period: 'year',
        description: 'Best value for serious daily budgeting.',
      ),
    ];
  }

  @override
  Future<SubscriptionPurchaseResult> purchase(String offerId) async {
    return const SubscriptionPurchaseResult(
      isPremium: false,
      message: 'RevenueCat keys are not configured for this build yet.',
    );
  }

  @override
  Future<SubscriptionPurchaseResult> restore() async {
    return const SubscriptionPurchaseResult(
      isPremium: false,
      message: 'RevenueCat keys are not configured for this build yet.',
    );
  }

  @override
  Future<SubscriptionStatus> status() async {
    return const SubscriptionStatus(
      isConfigured: false,
      isPremium: false,
      message: 'Subscription backend not configured for this build.',
    );
  }
}
