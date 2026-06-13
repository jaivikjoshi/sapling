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

  /// ISO date (yyyy-MM-dd) of the last scheduler run, used to skip same-day
  /// re-runs caused by widget rebuilds.
  String? _lastSchedulerRunDate;

  /// User ID we last ran schedulers for. When the signed-in user changes
  /// (session restore or explicit login) we force a re-run even if the date
  /// is the same.
  String? _lastSchedulerUserId;

  /// Prevents concurrent scheduler runs if build fires multiple times quickly.
  bool _schedulerRunning = false;

  /// Set when a user-switch run was requested while a scheduler was in flight.
  bool _schedulerRerunPending = false;

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

  /// Re-run schedulers when the app returns to the foreground. The
  /// date-deduplication inside [_maybeRunSchedulers] means this is a no-op
  /// if the app is brought forward multiple times on the same calendar day.
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

  /// Runs schedulers unless they already ran today for the current user.
  /// Pass [forceUser] = true to bypass the date check when the signed-in
  /// user changed (e.g. session restored, sign-in completed).
  void _maybeRunSchedulers({bool forceUser = false}) {
    if (_schedulerRunning) {
      if (forceUser) _schedulerRerunPending = true;
      return;
    }
    final today = _dateKey(DateTime.now());
    final userId = ref.read(currentUserProvider)?.id;
    final sameDay = _lastSchedulerRunDate == today;
    final sameUser = _lastSchedulerUserId == userId;
    if (!forceUser && sameDay && sameUser) return;
    _schedulerRunning = true;
    Future.microtask(
      () => _runSchedulers(
        ref,
        scheduledDate: today,
        scheduledUserId: userId,
      ),
    );
  }

  Future<void> _runSchedulers(
    WidgetRef ref, {
    required String scheduledDate,
    required String? scheduledUserId,
  }) async {
    var succeeded = false;
    try {
      if (ref.read(currentUserProvider)?.id != scheduledUserId) return;
      await ref.read(cycleBoundaryWatcherProvider).checkAndUpdate(DateTime.now());
      final now = DateTime.now();
      await ref.read(paydayAutoPosterProvider).runForDate(now);
      await ref.read(billAutoPosterProvider).runForDate(now);
      await ref.read(notificationSchedulerProvider).rescheduleAll();
      await ref.read(snapshotWriterProvider).writeSnapshot();
      succeeded = true;
    } catch (e, st) {
      debugPrint('[Scheduler] error: $e\n$st');
    } finally {
      _schedulerRunning = false;
      final currentUserId = ref.read(currentUserProvider)?.id;
      if (succeeded && currentUserId == scheduledUserId) {
        _lastSchedulerRunDate = scheduledDate;
        _lastSchedulerUserId = scheduledUserId;
      }
      final userChanged = currentUserId != scheduledUserId;
      final rerun = _schedulerRerunPending || userChanged;
      _schedulerRerunPending = false;
      if (rerun) {
        _maybeRunSchedulers(forceUser: userChanged);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-run schedulers when the signed-in user changes. This covers two
    // cases: (1) Supabase session being restored after the first build fires,
    // and (2) the user explicitly signing in from the auth screen.
    ref.listen(currentUserProvider, (previous, current) {
      if (current?.id != _lastSchedulerUserId) {
        _maybeRunSchedulers(forceUser: true);
      }
    });

    // Run on every build; no-op if already ran today for the same user.
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
