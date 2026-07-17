import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_dart_defines.dart';
import 'core/notifications/closeout_notification_service.dart';
import 'core/observability/production_observability.dart';

/// Capture the launch link and process it immediately when it is an auth link.
Future<Uri?> _handleInitialDeepLink() async {
  try {
    final appLinks = AppLinks();
    final uri = await appLinks.getInitialLink();
    if (uri != null && _isAuthCallback(uri)) {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
      return null;
    }
    return uri;
  } catch (_) {
    // Ignore: link may be expired, invalid, or not an auth URL
    return null;
  }
}

bool _isAuthCallback(Uri uri) {
  return uri.scheme == 'com.jaivik.leko' &&
      (uri.host == 'auth-callback' || uri.host == 'login-callback');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ProductionObservability.run(_bootstrapAndRun);
}

Future<void> _bootstrapAndRun() async {
  final url = SupabaseDartDefines.url;
  final apiKey = SupabaseDartDefines.apiKey;
  if (url.isEmpty || apiKey.isEmpty) {
    throw StateError(
      'Supabase is not configured. If your free project was paused, open '
      'https://supabase.com/dashboard, restore it, then copy Project URL and '
      'publishable key from the project Connect dialog.\n\n'
      'Run with:\n'
      '  flutter run --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co '
      '--dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>\n\n'
      'Or edit sapling/run_dev.sh with those values and run ./run_dev.sh',
    );
  }

  await Supabase.initialize(url: url, anonKey: apiKey);
  // Supabase redirect URLs (add in Dashboard → Auth → URL config):
  // com.jaivik.leko://auth-callback (email verification)
  // com.jaivik.leko://login-callback (OAuth)

  final initialDeepLink = await _handleInitialDeepLink();

  await CloseoutNotificationService.instance.init();
  if (Platform.isIOS || Platform.isAndroid) {
    await HomeWidget.setAppGroupId('group.com.leko.app');
  }

  runApp(ProviderScope(child: LekoApp(initialDeepLink: initialDeepLink)));
}
