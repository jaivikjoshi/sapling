import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/notifications/closeout_notification_service.dart';
import 'core/providers/auth_providers.dart';
import 'core/providers/bills_providers.dart';
import 'core/providers/integration_providers.dart';
import 'core/providers/recurring_income_providers.dart';
import 'core/providers/scheduler_providers.dart';
import 'core/providers/settings_providers.dart';
import 'core/providers/widget_snapshot_providers.dart';
import 'core/routing/app_router.dart';
import 'core/scheduling/scheduler_run_coordinator.dart';
import 'core/theme/leko_theme.dart';
import 'data/integrations/platform_notification_provider.dart';

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
  bool _notificationUserSynced = false;

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
    final today = _dateKey(DateTime.now());
    final userId = ref.read(currentUserProvider)?.id;
    if (!_schedulerRunCoordinator.requestRun(
      today: today,
      userId: userId,
      forceUser: forceUser,
    )) {
      return;
    }
    final runToken = _schedulerRunCoordinator.markRunStarted();
    Future.microtask(
      () => _runSchedulers(
        ref,
        today: today,
        userId: userId!,
        runToken: runToken,
      ),
    );
  }

  bool _schedulerRunStillValid(WidgetRef ref, String userId, int runToken) {
    if (!_schedulerRunCoordinator.isRunTokenActive(runToken)) return false;
    return ref.read(currentUserProvider)?.id == userId;
  }

  Future<void> _runSchedulers(
    WidgetRef ref, {
    required String today,
    required String userId,
    required int runToken,
  }) async {
    try {
      if (!_schedulerRunStillValid(ref, userId, runToken)) {
        _schedulerRunCoordinator.markRunEndedWithoutSuccess();
        return;
      }
      await ref
          .read(cycleBoundaryWatcherProvider)
          .checkAndUpdate(DateTime.now());
      if (!_schedulerRunStillValid(ref, userId, runToken)) {
        _schedulerRunCoordinator.markRunEndedWithoutSuccess();
        return;
      }
      final now = DateTime.now();
      await ref.read(paydayAutoPosterProvider).runForDate(now);
      if (!_schedulerRunStillValid(ref, userId, runToken)) {
        _schedulerRunCoordinator.markRunEndedWithoutSuccess();
        return;
      }
      await ref.read(billAutoPosterProvider).runForDate(now);
      if (!_schedulerRunStillValid(ref, userId, runToken)) {
        _schedulerRunCoordinator.markRunEndedWithoutSuccess();
        return;
      }
      await ref.read(notificationSchedulerProvider).rescheduleAll();
      if (!_schedulerRunStillValid(ref, userId, runToken)) {
        _schedulerRunCoordinator.markRunEndedWithoutSuccess();
        return;
      }
      await ref.read(snapshotWriterProvider).writeSnapshot();
      if (!_schedulerRunStillValid(ref, userId, runToken)) {
        _schedulerRunCoordinator.markRunEndedWithoutSuccess();
        return;
      }
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

  void _syncNotificationImportUser(WidgetRef ref, User? previous, User? current) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final provider = ref.read(notificationImportProvider);
    if (provider is! PlatformNotificationProvider) return;
    if (previous != null && (current == null || current.id != previous.id)) {
      provider.clearDraftsForUser(previous.id).ignore();
    }
    provider.setActiveUserId(current?.id).ignore();
  }

  @override
  Widget build(BuildContext context) {
    // Re-run schedulers when the signed-in user changes. This covers two
    // cases: (1) Supabase session being restored after the first build fires,
    // and (2) the user explicitly signing in from the auth screen.
    ref.listen(currentUserProvider, (previous, current) {
      _syncNotificationImportUser(ref, previous, current);
      if (current == null) {
        _schedulerRunCoordinator.invalidateActiveRun();
        _schedulerRunCoordinator.lastRunDate = null;
        _schedulerRunCoordinator.lastUserId = null;
        return;
      }
      if (previous != null && current.id != previous.id) {
        _schedulerRunCoordinator.invalidateActiveRun();
      }
      if (current.id != _schedulerRunCoordinator.lastUserId) {
        _maybeRunSchedulers(forceUser: true);
      }
    });

    if (!_notificationUserSynced) {
      _notificationUserSynced = true;
      _syncNotificationImportUser(ref, null, ref.read(currentUserProvider));
    }

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
