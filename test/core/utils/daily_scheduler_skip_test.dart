import 'package:flutter_test/flutter_test.dart';
import 'package:leko/core/utils/daily_scheduler_skip.dart';

void main() {
  group('shouldSkipEnqueueDailySchedulers', () {
    const today = '2026-05-22';

    test('skips when no signed-in user so Drift is not mutated', () {
      expect(
        shouldSkipEnqueueDailySchedulers(
          schedulerRunning: false,
          currentUserId: null,
          todayDateKey: today,
          lastRunDateKey: null,
          lastRunUserId: null,
          forceUserChange: false,
        ),
        isTrue,
      );
    });

    test('runs first time for a signed-in user', () {
      expect(
        shouldSkipEnqueueDailySchedulers(
          schedulerRunning: false,
          currentUserId: 'user-a',
          todayDateKey: today,
          lastRunDateKey: null,
          lastRunUserId: null,
          forceUserChange: false,
        ),
        isFalse,
      );
    });

    test('skips same calendar day for same user unless forced', () {
      expect(
        shouldSkipEnqueueDailySchedulers(
          schedulerRunning: false,
          currentUserId: 'user-a',
          todayDateKey: today,
          lastRunDateKey: today,
          lastRunUserId: 'user-a',
          forceUserChange: false,
        ),
        isTrue,
      );
    });

    test('does not skip same day when user changed and force flag set', () {
      expect(
        shouldSkipEnqueueDailySchedulers(
          schedulerRunning: false,
          currentUserId: 'user-b',
          todayDateKey: today,
          lastRunDateKey: today,
          lastRunUserId: 'user-a',
          forceUserChange: true,
        ),
        isFalse,
      );
    });

    test('skips while a scheduler run is in flight', () {
      expect(
        shouldSkipEnqueueDailySchedulers(
          schedulerRunning: true,
          currentUserId: 'user-a',
          todayDateKey: today,
          lastRunDateKey: null,
          lastRunUserId: null,
          forceUserChange: false,
        ),
        isTrue,
      );
    });
  });
}
