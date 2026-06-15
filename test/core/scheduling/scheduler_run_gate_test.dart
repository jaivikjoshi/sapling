import 'package:flutter_test/flutter_test.dart';
import 'package:leko/core/scheduling/scheduler_run_gate.dart';

void main() {
  group('SchedulerRunGate', () {
    test('skips only after a successful run for the same day and user', () {
      final gate = SchedulerRunGate();
      gate.markStarted();
      gate.markFinished(success: true, today: '2026-05-16', userId: 'user-a');

      expect(
        gate.shouldSkip(today: '2026-05-16', userId: 'user-a'),
        isTrue,
      );
      expect(
        gate.shouldSkip(today: '2026-05-16', userId: 'user-b'),
        isFalse,
      );
      expect(
        gate.shouldSkip(today: '2026-05-17', userId: 'user-a'),
        isFalse,
      );
    });

    test('failed run does not block retries on the same day', () {
      final gate = SchedulerRunGate();
      gate.markStarted();
      gate.markFinished(success: false, today: '2026-05-16', userId: 'user-a');

      expect(
        gate.shouldSkip(today: '2026-05-16', userId: 'user-a'),
        isFalse,
      );
    });

    test('forceUser bypasses successful same-day deduplication', () {
      final gate = SchedulerRunGate();
      gate.markStarted();
      gate.markFinished(success: true, today: '2026-05-16', userId: 'user-a');

      expect(
        gate.shouldSkip(
          today: '2026-05-16',
          userId: 'user-a',
          forceUser: true,
        ),
        isFalse,
      );
    });

    test('concurrent trigger sets retry flag for follow-up run', () {
      final gate = SchedulerRunGate();
      gate.markStarted();

      expect(
        gate.shouldSkip(today: '2026-05-16', userId: 'user-a'),
        isTrue,
      );
      expect(gate.consumeRetryNeeded(), isTrue);
      expect(gate.consumeRetryNeeded(), isFalse);
    });
  });
}
