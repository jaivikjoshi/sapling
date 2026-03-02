import '../models/enums.dart';

abstract final class SettingsValidation {
  static String? validateRolloverType({
    required RolloverResetType type,
    required String? anchorId,
  }) {
    if (type == RolloverResetType.paydayBased &&
        (anchorId == null || anchorId.isEmpty)) {
      return 'Payday-based rollover requires selecting a Payday Anchor.';
    }
    return null;
  }

  static String? validateAutoPost({
    required PaydayBehavior behavior,
    required double? expectedAmount,
  }) {
    if (behavior == PaydayBehavior.autoPostExpected &&
        (expectedAmount == null || expectedAmount <= 0)) {
      return 'Auto-post requires a positive expected amount.';
    }
    return null;
  }

  static String? validateBaselineDays(int days) {
    if (![30, 60, 90].contains(days)) {
      return 'Baseline must be 30, 60, or 90 days.';
    }
    return null;
  }

  static String? validateOnboardingComplete({
    required bool hasIncomesForAnchor,
    required RolloverResetType rolloverType,
    required String? anchorId,
  }) {
    if (rolloverType == RolloverResetType.paydayBased) {
      if (!hasIncomesForAnchor) {
        return 'Add at least one recurring income for payday-based rollover.';
      }
      if (anchorId == null || anchorId.isEmpty) {
        return 'Select a Payday Anchor income schedule.';
      }
    }
    return null;
  }
}
