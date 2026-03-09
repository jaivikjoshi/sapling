import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/notifications/closeout_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ckunakmbxrpinnyzogez.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNrdW5ha21ieHJwaW5ueXpvZ2V6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1OTc2MzEsImV4cCI6MjA4ODE3MzYzMX0.XoYETYaE3Lw9-Oi3pc2F2pcXrD65qEnLmCfuTZqAjZg',
  );
  // For Google OAuth: add redirect URL in Supabase Dashboard → Auth → URL config:
  // com.jaivik.sapling://login-callback

  await CloseoutNotificationService.instance.init();
  await HomeWidget.setAppGroupId('group.com.sapling.app');

  runApp(const ProviderScope(child: SaplingApp()));
}
