import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'app.dart';
import 'core/notifications/closeout_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CloseoutNotificationService.instance.init();
  await HomeWidget.setAppGroupId('group.com.sapling.app');
  runApp(const ProviderScope(child: SaplingApp()));
}
