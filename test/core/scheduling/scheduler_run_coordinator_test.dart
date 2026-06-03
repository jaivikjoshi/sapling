import 'package:flutter_test/flutter_test.dart';
import 'package:leko/core/scheduling/scheduler_run_coordinator.dart';

void main() {
  group('SchedulerRunCoordinator', () {
    test('does not run when userId is null', () {
      final gate = SchedulerRunCoordinator();
      expect(
        gate.requestRun(today: '2026-06-03', userId: null),
        isFalse,
      );
      expect(gate.running, isFalse);
      expect(gate.rerunPending, isFalse);
    });

    test('deduplicates same calendar day for same user', () {
      final gate = SchedulerRunCoordinator()
        ..lastRunDate = '2026-06-03'
        ..lastUserId = 'user-a';

      expect(
        gate.requestRun(today: '2026-06-03', userId: 'user-a'),
        isFalse,
      );
      expect(
        gate.requestRun(
          today: '2026-06-03',
          userId: 'user-a',
          forceUser: true,
        ),
        isTrue,
      );
    });

    test('runs again when signed-in user changes', () {
      final gate = SchedulerRunCoordinator()
        ..lastRunDate = '2026-06-03'
        ..lastUserId = 'user-a';

      expect(
        gate.requestRun(today: '2026-06-03', userId: 'user-b'),
        isTrue,
      );
    });

    test('queues rerun when a run is already in flight', () {
      final gate = SchedulerRunCoordinator()..running = true;

      expect(
        gate.requestRun(today: '2026-06-03', userId: 'user-a'),
        isFalse,
      );
      expect(gate.rerunPending, isTrue);
      expect(gate.consumeRerunPending(), isTrue);
      expect(gate.consumeRerunPending(), isFalse);
    });
  });
}
