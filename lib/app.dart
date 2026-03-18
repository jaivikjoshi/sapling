import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/notifications/closeout_notification_service.dart';
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

class _LekoAppState extends ConsumerState<LekoApp> {
  bool _closeoutCallbackSet = false;
  bool _schedulersRunOnce = false;
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _deepLinkSubscription = AppLinks().uriLinkStream.listen((uri) {
      if (_isAuthCallback(uri)) {
        Supabase.instance.client.auth.getSessionFromUrl(uri).ignore();
      }
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
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
      title: 'Leko',
      theme: LekoTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
