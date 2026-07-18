import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/config/production_dart_defines.dart';
import '../../domain/monetization/subscription_service.dart';

class RevenueCatSubscriptionService implements SubscriptionService {
  RevenueCatSubscriptionService({String entitlementId = 'premium'})
    : _entitlementId = entitlementId;

  final String _entitlementId;
  bool _configured = false;

  bool get canConfigure => _apiKey.isNotEmpty;

  Future<void> configure({String? appUserId}) async {
    if (_configured || !canConfigure) return;
    await Purchases.setLogLevel(LogLevel.warn);
    final configuration = PurchasesConfiguration(_apiKey);
    if (appUserId != null && appUserId.isNotEmpty) {
      configuration.appUserID = appUserId;
    }
    await Purchases.configure(configuration);
    _configured = true;
  }

  @override
  Future<List<SubscriptionOffer>> offers() async {
    if (!canConfigure) return const UnconfiguredSubscriptionService().offers();
    await configure();
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) {
      return const UnconfiguredSubscriptionService().offers();
    }
    return current.availablePackages
        .map((package) {
          final product = package.storeProduct;
          return SubscriptionOffer(
            id: package.identifier,
            title: product.title,
            price: product.priceString,
            period: _periodLabel(package.packageType),
            description: product.description,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<SubscriptionPurchaseResult> purchase(String offerId) async {
    if (!canConfigure) {
      return const UnconfiguredSubscriptionService().purchase(offerId);
    }
    await configure();
    final offerings = await Purchases.getOfferings();
    final packages = offerings.current?.availablePackages ?? const [];
    final package = packages.where((p) => p.identifier == offerId).firstOrNull;
    if (package == null) {
      return const SubscriptionPurchaseResult(
        isPremium: false,
        message: 'This offer is not available right now.',
      );
    }
    final info = await Purchases.purchase(PurchaseParams.package(package));
    final active = _isPremium(info.customerInfo);
    return SubscriptionPurchaseResult(
      isPremium: active,
      message: active ? 'Premium is active.' : 'Purchase was not completed.',
    );
  }

  @override
  Future<SubscriptionPurchaseResult> restore() async {
    if (!canConfigure) {
      return const UnconfiguredSubscriptionService().restore();
    }
    await configure();
    final info = await Purchases.restorePurchases();
    final active = _isPremium(info);
    return SubscriptionPurchaseResult(
      isPremium: active,
      message:
          active ? 'Premium restored.' : 'No active Premium purchase found.',
    );
  }

  @override
  Future<SubscriptionStatus> status() async {
    if (!canConfigure) {
      return const UnconfiguredSubscriptionService().status();
    }
    await configure();
    final info = await Purchases.getCustomerInfo();
    return SubscriptionStatus(
      isConfigured: true,
      isPremium: _isPremium(info),
      managementUrl:
          info.managementURL == null ? null : Uri.tryParse(info.managementURL!),
    );
  }

  bool _isPremium(CustomerInfo info) {
    return info.entitlements.active.containsKey(_entitlementId);
  }

  String get _apiKey {
    if (Platform.isIOS || Platform.isMacOS) {
      return ProductionDartDefines.revenueCatAppleKey;
    }
    if (Platform.isAndroid) {
      return ProductionDartDefines.revenueCatGoogleKey;
    }
    return '';
  }

  String _periodLabel(PackageType type) {
    return switch (type) {
      PackageType.monthly => 'month',
      PackageType.annual => 'year',
      PackageType.weekly => 'week',
      PackageType.twoMonth => '2 months',
      PackageType.threeMonth => '3 months',
      PackageType.sixMonth => '6 months',
      PackageType.lifetime => 'lifetime',
      _ => 'period',
    };
  }
}
