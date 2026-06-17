class ProductionDartDefines {
  const ProductionDartDefines._();

  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const environment = String.fromEnvironment(
    'LEKO_ENVIRONMENT',
    defaultValue: 'development',
  );
  static const release = String.fromEnvironment('LEKO_RELEASE');
  static const revenueCatAppleKey = String.fromEnvironment(
    'REVENUECAT_APPLE_API_KEY',
  );
  static const revenueCatGoogleKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_API_KEY',
  );
  static const analyticsEnabled = bool.fromEnvironment(
    'LEKO_ANALYTICS_ENABLED',
    defaultValue: false,
  );
}
