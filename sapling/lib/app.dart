import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/closeout_notification_service.dart';
import 'core/providers/bills_providers.dart';
import 'core/providers/recurring_income_providers.dart';
import 'core/providers/scheduler_providers.dart';
import 'core/providers/settings_providers.dart';
import 'core/providers/widget_snapshot_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/sapling_theme.dart';

class SaplingApp extends ConsumerStatefulWidget {
  const SaplingApp({super.key});

  @override
  ConsumerState<SaplingApp> createState() => _SaplingAppState();
}

class _SaplingAppState extends ConsumerState<SaplingApp> {
  bool _closeoutCallbackSet = false;
  bool _schedulersRunOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_closeoutCallbackSet) {
      _closeoutCallbackSet = true;
      final router = ref.read(routerProvider);
      CloseoutNotificationService.instance.setCloseoutCallback((_) {
        router.go('/closeout');
      });
    }
  }

  Future<void> _runSchedulers(WidgetRef ref) async {
    try {
      final boundary = ref.read(cycleBoundaryWatcherProvider);
      await boundary.checkAndUpdate(DateTime.now());
      final poster = ref.read(paydayAutoPosterProvider);
      await poster.runForDate(DateTime.now());
      final scheduler = ref.read(notificationSchedulerProvider);
      await scheduler.rescheduleAll();
      await ref.read(snapshotWriterProvider).writeSnapshot();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_schedulersRunOnce) {
      _schedulersRunOnce = true;
      Future.microtask(() => _runSchedulers(ref));
    }
    ref.listen(settingsStreamProvider, (prev, next) {
      next.whenData((_) async {
        final scheduler = ref.read(notificationSchedulerProvider);
        await scheduler.rescheduleAll();
      });
    });
    ref.listen(recurringIncomesProvider, (prev, next) {
      next.whenData((_) async {
        final scheduler = ref.read(notificationSchedulerProvider);
        await scheduler.rescheduleAll();
      });
    });
    ref.listen(billsStreamProvider, (prev, next) {
      next.whenData((_) async {
        final scheduler = ref.read(notificationSchedulerProvider);
        await scheduler.rescheduleAll();
      });
    });
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Sapling',
      theme: SaplingTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
