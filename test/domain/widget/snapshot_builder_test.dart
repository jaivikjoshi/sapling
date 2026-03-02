import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/domain/models/daily_snapshot.dart';
import 'package:sapling/domain/services/allowance_engine.dart';
import 'package:sapling/domain/services/closeout_service.dart';
import 'package:sapling/domain/services/cycle_window_calculator.dart';
import 'package:sapling/domain/widget/snapshot_builder.dart';

void main() {
  group('SnapshotBuilder.treeStageFromStreak', () {
    test('0 streak returns seedling', () {
      expect(SnapshotBuilder.treeStageFromStreak(0), 'seedling');
    });
    test('1 streak returns sapling', () {
      expect(SnapshotBuilder.treeStageFromStreak(1), 'sapling');
    });
    test('6 streak returns sapling', () {
      expect(SnapshotBuilder.treeStageFromStreak(6), 'sapling');
    });
    test('7 streak returns tree', () {
      expect(SnapshotBuilder.treeStageFromStreak(7), 'tree');
    });
    test('10 streak returns tree', () {
      expect(SnapshotBuilder.treeStageFromStreak(10), 'tree');
    });
  });

  group('SnapshotBuilder.formatCloseoutStatus', () {
    test('zero streak within budget', () {
      expect(
        SnapshotBuilder.formatCloseoutStatus(0, true),
        'Within budget',
      );
    });
    test('zero streak over budget', () {
      expect(
        SnapshotBuilder.formatCloseoutStatus(0, false),
        'Over budget',
      );
    });
    test('1 day streak within budget', () {
      expect(
        SnapshotBuilder.formatCloseoutStatus(1, true),
        '1 day streak · Within budget',
      );
    });
    test('3 days streak over budget', () {
      expect(
        SnapshotBuilder.formatCloseoutStatus(3, false),
        '3 days streak · Over budget',
      );
    });
  });

  group('SnapshotBuilder.fromPaycheck', () {
    test('builds snapshot with allowance and streak', () {
      final allowance = PaycheckAllowanceResult(
        balance: 1000,
        allowanceToday: 85,
        bankedAllowance: 10,
        behindAmount: 0,
        projectedIncome: 3000,
        projectedBills: 500,
        daysLeft: 15,
        cycleWindow: CycleWindow(
          start: DateTime(2025, 6, 1),
          end: DateTime(2025, 7, 1),
        ),
      );
      final streak = const StreakResult(
        currentStreak: 3,
        todayWithinBudget: true,
      );
      final snapshot = SnapshotBuilder.fromPaycheck(allowance, streak);
      expect(snapshot.todayAllowance, 85);
      expect(snapshot.behindAmount, 0);
      expect(snapshot.primaryGoalProgress, null);
      expect(snapshot.treeStage, 'sapling');
      expect(
        snapshot.closeoutStatus,
        '3 days streak · Within budget',
      );
    });
  });

  group('DailySnapshot.toJson/fromJson', () {
    test('round-trip preserves data', () {
      final s = DailySnapshot(
        todayAllowance: 50,
        behindAmount: 10,
        primaryGoalProgress: 0.25,
        treeStage: 'sapling',
        closeoutStatus: '2 days streak · Within budget',
        timestamp: DateTime(2025, 6, 15, 12, 0),
      );
      final json = s.toJson();
      final decoded = DailySnapshot.fromJson(json);
      expect(decoded, isNotNull);
      expect(decoded!.todayAllowance, s.todayAllowance);
      expect(decoded.behindAmount, s.behindAmount);
      expect(decoded.primaryGoalProgress, s.primaryGoalProgress);
      expect(decoded.treeStage, s.treeStage);
      expect(decoded.closeoutStatus, s.closeoutStatus);
      expect(decoded.timestamp.toIso8601String(), s.timestamp.toIso8601String());
    });
    test('fromJson null returns null', () {
      expect(DailySnapshot.fromJson(null), null);
    });
  });
}
