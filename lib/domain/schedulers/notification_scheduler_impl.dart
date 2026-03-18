import '../../core/notifications/closeout_notification_service.dart';
import '../../data/db/leko_database.dart';
import '../../data/repositories/bills_repository.dart';
import '../../data/repositories/recurring_income_repository.dart';
import '../../data/repositories/scheduler_metadata_repository.dart';
import '../../data/repositories/settings_repository.dart';
import 'schedule_dates.dart';

/// Schedules and cancels payday, bill, overspend, and closeout notifications
/// based on settings and data. Call rescheduleAll on launch and when data changes.
class NotificationSchedulerImpl {
  final CloseoutNotificationService _notifications;
  final SettingsRepository _settingsRepo;
  final RecurringIncomeRepository _incomeRepo;
  final BillsRepository _billsRepo;
  final SchedulerMetadataRepository _metadataRepo;

  static const _keyLastRun = 'lastSchedulerRunAt';

  NotificationSchedulerImpl(
    this._notifications,
    this._settingsRepo,
    this._incomeRepo,
    this._billsRepo,
    this._metadataRepo,
  );

  /// Reschedule all notifications from current settings and data. Best-effort.
  Future<void> rescheduleAll() async {
    final now = DateTime.now();
    final settings = await _settingsRepo.get();
    try {
      await _metadataRepo.set(_keyLastRun, now.toIso8601String());
    } catch (_) {}

    if (settings.nightlyCloseoutEnabled) {
      await _notifications.scheduleDailyAt(settings.nightlyCloseoutTime);
    } else {
      await _notifications.cancelCloseoutNotification();
    }

    if (settings.paydayEnabled) {
      final incomes = await _incomeRepo.getAll();
      for (final income in incomes) {
        await _notifications.cancelPaydayReminder(income.id);
        if (income.reminderEnabled) {
          final at = ScheduleDates.nextPaydayReminderTime(income, now);
          if (at.isAfter(now)) {
            await _notifications.schedulePaydayReminder(income, at);
          }
        }
      }
    } else {
      final incomes = await _incomeRepo.getAll();
      for (final income in incomes) {
        await _notifications.cancelPaydayReminder(income.id);
      }
    }

    if (settings.billsEnabled) {
      final bills = await _billsRepo.getAll();
      for (final bill in bills) {
        await _notifications.cancelBillReminder(bill.id);
        if (bill.reminderEnabled) {
          final at = ScheduleDates.nextBillReminderTime(bill, now);
          if (at.isAfter(now)) {
            await _notifications.scheduleBillReminder(bill, at);
          }
        }
      }
    } else {
      final bills = await _billsRepo.getAll();
      for (final bill in bills) {
        await _notifications.cancelBillReminder(bill.id);
      }
    }

    if (!settings.overspendEnabled) {
      await _notifications.cancelOverspendWarning();
    }
  }

  /// Call when overspend is detected (e.g. after adding expense) to show alert.
  Future<void> showOverspendNow() async {
    await _notifications.showOverspendNow();
  }

  Future<String?> getLastRunAt() => _metadataRepo.get(_keyLastRun);
}
