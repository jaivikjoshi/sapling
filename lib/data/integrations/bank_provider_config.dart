class BankProviderConfig {
  const BankProviderConfig({
    required this.region,
    required this.providerId,
    required this.displayName,
    required this.consentCopy,
  });

  final String region;
  final String providerId;
  final String displayName;
  final String consentCopy;

  static BankProviderConfig fromDartDefines({
    String region = const String.fromEnvironment(
      'LEKO_BANK_REGION',
      defaultValue: 'CA',
    ),
    String providerId = const String.fromEnvironment('LEKO_BANK_PROVIDER_ID'),
    String displayName = const String.fromEnvironment(
      'LEKO_BANK_PROVIDER_NAME',
    ),
    String consentCopy = const String.fromEnvironment('LEKO_BANK_CONSENT_COPY'),
  }) {
    final normalizedRegion = _normalizeRegion(region);
    final defaults = _defaultsForRegion(normalizedRegion);
    return BankProviderConfig(
      region: normalizedRegion,
      providerId:
          providerId.trim().isEmpty ? defaults.providerId : providerId.trim(),
      displayName:
          displayName.trim().isEmpty
              ? defaults.displayName
              : displayName.trim(),
      consentCopy:
          consentCopy.trim().isEmpty
              ? defaults.consentCopy
              : consentCopy.trim(),
    );
  }
}

BankProviderConfig _defaultsForRegion(String region) {
  return switch (region) {
    'CA' => const BankProviderConfig(
      region: 'CA',
      providerId: 'flinks',
      displayName: 'Flinks Connect',
      consentCopy:
          'Leko will send you to Flinks Connect to connect your Canadian bank. Leko never stores your bank username or password, and imported transactions stay as drafts until you approve them.',
    ),
    'US' => const BankProviderConfig(
      region: 'US',
      providerId: 'plaid',
      displayName: 'Plaid Link',
      consentCopy:
          'Leko will send you to Plaid Link to connect your bank. Leko never stores your bank username or password, and imported transactions stay as drafts until you approve them.',
    ),
    _ => const BankProviderConfig(
      region: 'GLOBAL',
      providerId: 'trusted_aggregator',
      displayName: 'Trusted bank connection',
      consentCopy:
          'Leko will send you to a trusted aggregator to connect your bank. Leko never stores your bank username or password, and imported transactions stay as drafts until you approve them.',
    ),
  };
}

String _normalizeRegion(String region) {
  final normalized = region.trim().toUpperCase();
  if (normalized == 'CANADA') return 'CA';
  if (normalized == 'UNITED_STATES' || normalized == 'USA') return 'US';
  if (normalized.isEmpty) return 'CA';
  return normalized;
}
