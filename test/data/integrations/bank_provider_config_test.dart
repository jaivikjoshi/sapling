import 'package:flutter_test/flutter_test.dart';
import 'package:leko/data/integrations/bank_provider_config.dart';

void main() {
  test('defaults Canada bank integrations to Flinks Connect', () {
    final config = BankProviderConfig.fromDartDefines(region: 'CA');

    expect(config.region, 'CA');
    expect(config.providerId, 'flinks');
    expect(config.displayName, 'Flinks Connect');
    expect(config.consentCopy, contains('Canadian bank'));
    expect(config.consentCopy, contains('drafts until you approve'));
  });

  test('defaults US bank integrations to Plaid Link', () {
    final config = BankProviderConfig.fromDartDefines(region: 'US');

    expect(config.region, 'US');
    expect(config.providerId, 'plaid');
    expect(config.displayName, 'Plaid Link');
  });

  test('allows provider overrides from build configuration', () {
    final config = BankProviderConfig.fromDartDefines(
      region: 'canada',
      providerId: 'custom_provider',
      displayName: 'Custom Connect',
      consentCopy: 'Custom consent.',
    );

    expect(config.region, 'CA');
    expect(config.providerId, 'custom_provider');
    expect(config.displayName, 'Custom Connect');
    expect(config.consentCopy, 'Custom consent.');
  });
}
