import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/notifications/closeout_notification_service.dart';
import 'core/providers/auth_providers.dart';
import 'core/providers/bills_providers.dart';
import 'core/providers/recurring_income_providers.dart';
import 'core/providers/scheduler_providers.dart';
import 'core/providers/settings_providers.dart';
import 'core/providers/widget_snapshot_providers.dart';
import 'core/routing/app_router.dart';
import 'core/scheduling/scheduler_run_coordinator.dart';
import 'core/theme/leko_theme.dart';

bool _isAuthCallback(Uri uri) {
  return uri.scheme == 'com.jaivik.leko' &&
      (uri.host == 'auth-callback' || uri.host == 'login-callback');
}

class LekoApp extends ConsumerStatefulWidget {
  const LekoApp({super.key});

  @override
  ConsumerState<LekoApp> createState() => _LekoAppState();
}

class _LekoAppState extends ConsumerState<LekoApp> with WidgetsBindingObserver {
  bool _closeoutCallbackSet = false;
  final _schedulerRunCoordinator = SchedulerRunCoordinator();
  StreamSubscription<Uri>? _deepLinkSubscription;

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deepLinkSubscription = AppLinks().uriLinkStream.listen((uri) {
      if (_isAuthCallback(uri)) {
        Supabase.instance.client.auth.getSessionFromUrl(uri).ignore();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeRunSchedulers();
    }
  }

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

  void _maybeRunSchedulers({bool forceUser = false}) {
    final today = _dateKey(DateTime.now());
    final userId = ref.read(currentUserProvider)?.id;
    if (!_schedulerRunCoordinator.requestRun(
      today: today,
      userId: userId,
      forceUser: forceUser,
    )) {
      return;
    }
    _schedulerRunCoordinator.markRunStarted();
    Future.microtask(() => _runSchedulers(ref, today: today, userId: userId!));
  }

  Future<void> _runSchedulers(
    WidgetRef ref, {
    required String today,
    required String userId,
  }) async {
    try {
      final boundary = ref.read(cycleBoundaryWatcherProvider);
      await boundary.checkAndUpdate(DateTime.now());
      final now = DateTime.now();
      final poster = ref.read(paydayAutoPosterProvider);
      await poster.runForDate(now);
      final billPoster = ref.read(billAutoPosterProvider);
      await billPoster.runForDate(now);
      final scheduler = ref.read(notificationSchedulerProvider);
      await scheduler.rescheduleAll();
      await ref.read(snapshotWriterProvider).writeSnapshot();
      _schedulerRunCoordinator.markRunFinished(today: today, userId: userId);
    } catch (e, st) {
      debugPrint('[Scheduler] error: $e\n$st');
      _schedulerRunCoordinator.markRunEndedWithoutSuccess();
    } finally {
      _scheduleRerunIfNeeded();
    }
  }

  void _scheduleRerunIfNeeded() {
    if (!_schedulerRunCoordinator.consumeRerunPending()) return;
    _maybeRunSchedulers(forceUser: true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProvider, (previous, current) {
      if (current?.id != _schedulerRunCoordinator.lastUserId) {
        _maybeRunSchedulers(forceUser: true);
      }
    });
    _maybeRunSchedulers();

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
      title: 'Leko',
      theme: LekoTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
