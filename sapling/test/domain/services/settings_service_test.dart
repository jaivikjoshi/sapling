import 'package:flutter_test/flutter_test.dart';
import 'package:sapling/domain/models/enums.dart';
import 'package:sapling/domain/services/settings_service.dart';

void main() {
  group('SettingsValidation.validateRolloverType', () {
    test('monthly is always valid', () {
      expect(
        SettingsValidation.validateRolloverType(
          type: RolloverResetType.monthly,
          anchorId: null,
        ),
        isNull,
      );
    });

    test('payday_based without anchor returns error', () {
      expect(
        SettingsValidation.validateRolloverType(
          type: RolloverResetType.paydayBased,
          anchorId: null,
        ),
        isNotNull,
      );
    });

    test('payday_based with empty anchor returns error', () {
      expect(
        SettingsValidation.validateRolloverType(
          type: RolloverResetType.paydayBased,
          anchorId: '',
        ),
        isNotNull,
      );
    });

    test('payday_based with valid anchor passes', () {
      expect(
        SettingsValidation.validateRolloverType(
          type: RolloverResetType.paydayBased,
          anchorId: 'some-uuid',
        ),
        isNull,
      );
    });
  });

  group('SettingsValidation.validateAutoPost', () {
    test('confirm_actual is always valid', () {
      expect(
        SettingsValidation.validateAutoPost(
          behavior: PaydayBehavior.confirmActualOnPayday,
          expectedAmount: null,
        ),
        isNull,
      );
    });

    test('auto_post without expectedAmount returns error', () {
      expect(
        SettingsValidation.validateAutoPost(
          behavior: PaydayBehavior.autoPostExpected,
          expectedAmount: null,
        ),
        isNotNull,
      );
    });

    test('auto_post with zero amount returns error', () {
      expect(
        SettingsValidation.validateAutoPost(
          behavior: PaydayBehavior.autoPostExpected,
          expectedAmount: 0,
        ),
        isNotNull,
      );
    });

    test('auto_post with negative amount returns error', () {
      expect(
        SettingsValidation.validateAutoPost(
          behavior: PaydayBehavior.autoPostExpected,
          expectedAmount: -100,
        ),
        isNotNull,
      );
    });

    test('auto_post with positive amount passes', () {
      expect(
        SettingsValidation.validateAutoPost(
          behavior: PaydayBehavior.autoPostExpected,
          expectedAmount: 900.0,
        ),
        isNull,
      );
    });
  });

  group('SettingsValidation.validateBaselineDays', () {
    test('30 is valid', () {
      expect(SettingsValidation.validateBaselineDays(30), isNull);
    });

    test('60 is valid', () {
      expect(SettingsValidation.validateBaselineDays(60), isNull);
    });

    test('90 is valid', () {
      expect(SettingsValidation.validateBaselineDays(90), isNull);
    });

    test('45 is invalid', () {
      expect(SettingsValidation.validateBaselineDays(45), isNotNull);
    });
  });

  group('SettingsValidation.validateOnboardingComplete', () {
    test('monthly rollover always passes', () {
      expect(
        SettingsValidation.validateOnboardingComplete(
          hasIncomesForAnchor: false,
          rolloverType: RolloverResetType.monthly,
          anchorId: null,
        ),
        isNull,
      );
    });

    test('payday_based without incomes fails', () {
      expect(
        SettingsValidation.validateOnboardingComplete(
          hasIncomesForAnchor: false,
          rolloverType: RolloverResetType.paydayBased,
          anchorId: null,
        ),
        isNotNull,
      );
    });

    test('payday_based with incomes but no anchor fails', () {
      expect(
        SettingsValidation.validateOnboardingComplete(
          hasIncomesForAnchor: true,
          rolloverType: RolloverResetType.paydayBased,
          anchorId: null,
        ),
        isNotNull,
      );
    });

    test('payday_based with incomes and anchor passes', () {
      expect(
        SettingsValidation.validateOnboardingComplete(
          hasIncomesForAnchor: true,
          rolloverType: RolloverResetType.paydayBased,
          anchorId: 'some-uuid',
        ),
        isNull,
      );
    });
  });
}
