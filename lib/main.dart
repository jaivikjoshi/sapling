import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/notifications/closeout_notification_service.dart';

/// Process auth deep link when app was launched from email verification or OAuth callback.
Future<void> _handleAuthDeepLink() async {
  try {
    final appLinks = AppLinks();
    final uri = await appLinks.getInitialLink();
    if (uri != null && _isAuthCallback(uri)) {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    }
  } catch (_) {
    // Ignore: link may be expired, invalid, or not an auth URL
  }
}

bool _isAuthCallback(Uri uri) {
  return uri.scheme == 'com.jaivik.leko' &&
      (uri.host == 'auth-callback' || uri.host == 'login-callback');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ckunakmbxrpinnyzogez.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrdW5ha21ieHJwaW5ueXpvZ2V6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1OTc2MzEsImV4cCI6MjA4ODE3MzYzMX0.XoYETYaE3Lw9-Oi3pc2F2pcXrD65qEnLmCfuTZqAjZg',
  );
  // Supabase redirect URLs (add in Dashboard → Auth → URL config):
  // com.jaivik.leko://auth-callback (email verification)
  // com.jaivik.leko://login-callback (OAuth)

  await _handleAuthDeepLink();

  await CloseoutNotificationService.instance.init();
  await HomeWidget.setAppGroupId('group.com.leko.app');

  runApp(const ProviderScope(child: LekoApp()));
}
