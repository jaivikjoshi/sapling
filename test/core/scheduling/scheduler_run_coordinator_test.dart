import 'package:flutter_test/flutter_test.dart';
import 'package:leko/core/scheduling/scheduler_run_coordinator.dart';

void main() {
  group('SchedulerRunCoordinator', () {
    test('does not run while userId is null', () {
      final coordinator = SchedulerRunCoordinator();

      expect(
        coordinator.requestRun(today: '2026-06-16', userId: null),
        isFalse,
      );
      expect(coordinator.running, isFalse);
      expect(coordinator.rerunPending, isFalse);
    });

    test('deduplicates same day only after a successful run', () {
      final coordinator = SchedulerRunCoordinator();

      coordinator.markRunStarted();
      coordinator.markRunFinished(today: '2026-06-16', userId: 'user-a');

      expect(
        coordinator.requestRun(today: '2026-06-16', userId: 'user-a'),
        isFalse,
      );
      expect(
        coordinator.requestRun(today: '2026-06-16', userId: 'user-b'),
        isTrue,
      );
    });

    test('failed runs do not block same-day retries', () {
      final coordinator = SchedulerRunCoordinator();

      coordinator.markRunStarted();
      coordinator.markRunEndedWithoutSuccess();

      expect(
        coordinator.requestRun(today: '2026-06-16', userId: 'user-a'),
        isTrue,
      );
    });

    test('concurrent trigger queues one rerun', () {
      final coordinator = SchedulerRunCoordinator()..markRunStarted();

      expect(
        coordinator.requestRun(today: '2026-06-16', userId: 'user-a'),
        isFalse,
      );
      expect(coordinator.consumeRerunPending(), isTrue);
      expect(coordinator.consumeRerunPending(), isFalse);
    });

    test('invalidateActiveRun cancels in-flight token', () {
      final coordinator = SchedulerRunCoordinator();
      final runToken = coordinator.markRunStarted();

      expect(coordinator.isRunTokenActive(runToken), isTrue);
      coordinator.invalidateActiveRun();
      expect(coordinator.isRunTokenActive(runToken), isFalse);
      expect(coordinator.running, isFalse);
    });

    test('sign-out clears dedupe state so schedulers can rerun', () {
      final coordinator = SchedulerRunCoordinator();

      coordinator.markRunStarted();
      coordinator.markRunFinished(today: '2026-06-16', userId: 'user-a');
      coordinator.lastRunDate = null;
      coordinator.lastUserId = null;

      expect(
        coordinator.requestRun(today: '2026-06-16', userId: 'user-a'),
        isTrue,
      );
    });
  });
}
