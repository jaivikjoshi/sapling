import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/domain/models/enums.dart';
import 'package:sapling/domain/services/cycle_window_calculator.dart';

void main() {
  group('CycleWindowCalculator — monthly', () {
    test('mid-month returns first-of-month to first-of-next', () {
      final w = CycleWindowCalculator.compute(
        resetType: RolloverResetType.monthly,
        now: DateTime(2025, 6, 15),
      );
      expect(w.start, DateTime(2025, 6));
      expect(w.end, DateTime(2025, 7));
    });

    test('first day of month is in that month cycle', () {
      final w = CycleWindowCalculator.compute(
        resetType: RolloverResetType.monthly,
        now: DateTime(2025, 1, 1),
      );
      expect(w.start, DateTime(2025, 1));
      expect(w.end, DateTime(2025, 2));
    });

    test('last day of month is in that month cycle', () {
      final w = CycleWindowCalculator.compute(
        resetType: RolloverResetType.monthly,
        now: DateTime(2025, 1, 31),
      );
      expect(w.start, DateTime(2025, 1));
      expect(w.end, DateTime(2025, 2));
    });

    test('December wraps to January', () {
      final w = CycleWindowCalculator.compute(
        resetType: RolloverResetType.monthly,
        now: DateTime(2025, 12, 15),
      );
      expect(w.start, DateTime(2025, 12));
      expect(w.end, DateTime(2026, 1));
    });
  });

  group('CycleWindowCalculator — payday_based', () {
    test('biweekly anchor: now between two paydays', () {
      final w = CycleWindowCalculator.compute(
        resetType: RolloverResetType.paydayBased,
        now: DateTime(2025, 6, 20),
        anchorFrequency: 'biweekly',
        anchorNextPaydayDate: DateTime(2025, 6, 27),
      );
      expect(w.start, DateTime(2025, 6, 13));
      expect(w.end, DateTime(2025, 6, 27));
    });

    test('monthly anchor: now is before next payday', () {
      final w = CycleWindowCalculator.compute(
        resetType: RolloverResetType.paydayBased,
        now: DateTime(2025, 6, 10),
        anchorFrequency: 'monthly',
        anchorNextPaydayDate: DateTime(2025, 6, 15),
      );
      expect(w.start, DateTime(2025, 5, 15));
      expect(w.end, DateTime(2025, 6, 15));
    });

    test('weekly anchor: now is on payday date', () {
      final w = CycleWindowCalculator.compute(
        resetType: RolloverResetType.paydayBased,
        now: DateTime(2025, 6, 13),
        anchorFrequency: 'weekly',
        anchorNextPaydayDate: DateTime(2025, 6, 20),
      );
      expect(w.start, DateTime(2025, 6, 13));
      expect(w.end, DateTime(2025, 6, 20));
    });

    test('payday_based uses schedule dates not confirmed payday', () {
      // Even if the user hasn't confirmed income, the cycle boundary
      // follows the anchor schedule dates.
      final w = CycleWindowCalculator.compute(
        resetType: RolloverResetType.paydayBased,
        now: DateTime(2025, 7, 5),
        anchorFrequency: 'biweekly',
        anchorNextPaydayDate: DateTime(2025, 7, 11),
      );
      // Previous anchor date would be July 11 - 14 = June 27
      expect(w.start, DateTime(2025, 6, 27));
      expect(w.end, DateTime(2025, 7, 11));
    });

    test('anchor far in the past walks forward correctly', () {
      final w = CycleWindowCalculator.compute(
        resetType: RolloverResetType.paydayBased,
        now: DateTime(2025, 6, 20),
        anchorFrequency: 'biweekly',
        anchorNextPaydayDate: DateTime(2025, 5, 2),
      );
      // 5/2 -> 5/16 -> 5/30 -> 6/13 -> 6/27
      // now=6/20 is between 6/13 and 6/27
      expect(w.start, DateTime(2025, 6, 13));
      expect(w.end, DateTime(2025, 6, 27));
    });
  });

  group('CycleWindow.daysLeft', () {
    test('returns positive days', () {
      final w = CycleWindowCalculator.compute(
        resetType: RolloverResetType.monthly,
        now: DateTime(2025, 6, 15),
      );
      // From June 15 to July 1 = 16 days
      expect(w.daysLeft, greaterThan(0));
    });
  });
}
