import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../../data/db/leko_database.dart';

/// Schedules closeout, payday, bill, and overspend notifications.
class CloseoutNotificationService {
  CloseoutNotificationService._();
  static final CloseoutNotificationService instance = CloseoutNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const int _closeoutId = 1;
  static const int _paydayIdBase = 10;
  static const int _billIdBase = 100;
  static const int _overspendId = 200;

  void Function(String? result)? _onCloseoutTapped;

  void setCloseoutCallback(void Function(String? result) cb) {
    _onCloseoutTapped = cb;
  }

  Future<void> init() async {
    tz_data.initializeTimeZones();
    if (tz.local.name == 'UTC') {
      try {
        tz.setLocalLocation(tz.getLocation('America/New_York'));
      } catch (_) {}
    }
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onResponse,
    );
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(
                alert: true,
                badge: false,
                sound: true,
              ) ??
          false;
    }
    return true;
  }

  void _onResponse(NotificationResponse response) {
    final result = response.actionId ?? response.payload;
    _onCloseoutTapped?.call(result);
  }

  /// Schedule daily at hour:minute (local). Time string e.g. "21:00".
  Future<void> scheduleDailyAt(String timeString) async {
    final parts = timeString.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 21 : 21;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    const android = AndroidNotificationDetails(
      'closeout_channel',
      'Closeout',
      channelDescription: 'Nightly closeout reminder',
      importance: Importance.defaultImportance,
    );
    const ios = DarwinNotificationDetails(
      categoryIdentifier: 'closeout',
      presentAlert: true,
    );

    await _plugin.zonedSchedule(
      _closeoutId,
      'Nightly closeout',
      'Tap to see if you stayed within budget today',
      scheduled,
      NotificationDetails(android: android, iOS: ios),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelCloseoutNotification() async {
    await _plugin.cancel(_closeoutId);
  }

  int _paydayNotificationId(String incomeId) =>
      _paydayIdBase + (incomeId.hashCode.abs() % 89);
  int _billNotificationId(String billId) =>
      _billIdBase + (billId.hashCode.abs() % 99);

  Future<void> schedulePaydayReminder(RecurringIncome income, DateTime at) async {
    if (!income.reminderEnabled) return;
    final tzAt = tz.TZDateTime.from(at, tz.local);
    if (tzAt.isBefore(tz.TZDateTime.now(tz.local))) return;
    const android = AndroidNotificationDetails(
      'payday_channel',
      'Payday',
      channelDescription: 'Payday reminder',
      importance: Importance.defaultImportance,
    );
    const ios = DarwinNotificationDetails(
      categoryIdentifier: 'payday',
      presentAlert: true,
    );
    await _plugin.zonedSchedule(
      _paydayNotificationId(income.id),
      'Payday reminder',
      '${income.name} is today',
      tzAt,
      const NotificationDetails(android: android, iOS: ios),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelPaydayReminder(String incomeId) async {
    await _plugin.cancel(_paydayNotificationId(incomeId));
  }

  Future<void> scheduleBillReminder(Bill bill, DateTime at) async {
    if (!bill.reminderEnabled) return;
    final tzAt = tz.TZDateTime.from(at, tz.local);
    if (tzAt.isBefore(tz.TZDateTime.now(tz.local))) return;
    const android = AndroidNotificationDetails(
      'bills_channel',
      'Bills',
      channelDescription: 'Bill due reminder',
      importance: Importance.defaultImportance,
    );
    const ios = DarwinNotificationDetails(
      categoryIdentifier: 'bills',
      presentAlert: true,
    );
    await _plugin.zonedSchedule(
      _billNotificationId(bill.id),
      'Bill due',
      '${bill.name} due soon',
      tzAt,
      const NotificationDetails(android: android, iOS: ios),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelBillReminder(String billId) async {
    await _plugin.cancel(_billNotificationId(billId));
  }

  Future<void> scheduleOverspendWarning(DateTime at) async {
    final tzAt = tz.TZDateTime.from(at, tz.local);
    if (tzAt.isBefore(tz.TZDateTime.now(tz.local))) return;
    const android = AndroidNotificationDetails(
      'overspend_channel',
      'Overspend',
      channelDescription: 'Overspend alert',
      importance: Importance.high,
    );
    const ios = DarwinNotificationDetails(
      categoryIdentifier: 'overspend',
      presentAlert: true,
    );
    await _plugin.zonedSchedule(
      _overspendId,
      'Over budget',
      'You\'re over your daily allowance',
      tzAt,
      const NotificationDetails(android: android, iOS: ios),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelOverspendWarning() async {
    await _plugin.cancel(_overspendId);
  }

  /// Show overspend notification immediately (e.g. after saving expense).
  Future<void> showOverspendNow() async {
    const android = AndroidNotificationDetails(
      'overspend_channel',
      'Overspend',
      channelDescription: 'Overspend alert',
      importance: Importance.high,
    );
    const ios = DarwinNotificationDetails(
      categoryIdentifier: 'overspend',
      presentAlert: true,
    );
    await _plugin.show(
      _overspendId,
      'Over budget',
      'You\'re over your daily allowance',
      const NotificationDetails(android: android, iOS: ios),
    );
  }
}
