// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/goals_providers.dart';
import '../../core/providers/profile_providers.dart';
import '../../core/providers/recurring_income_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/services/profile_service.dart';
import '../recurring_income/recurring_income_form_sheet.dart';
import '../transactions/reconcile_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final user = ref.watch(currentUserProvider);
    final goals = ref.watch(goalsStreamProvider).valueOrNull ?? const [];
    final incomes = ref.watch(recurringIncomesProvider).valueOrNull ?? const [];
    final profileService = ref.watch(profileServiceProvider);

    return Scaffold(
      backgroundColor: _SettingsReferencePalette.background,
      body: SafeArea(
        child: settingsAsync.when(
          data:
              (settings) => _PrototypeSettingsBody(
                settings: settings,
                user: user,
                goals: goals,
                recurringIncomes: incomes,
                profileService: profileService,
              ),
          loading:
              () => const Center(
                child: CircularProgressIndicator(
                  color: _SettingsReferencePalette.navy,
                ),
              ),
          error:
              (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Settings failed to load.\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _SettingsReferencePalette.textSecondary,
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

class _PrototypeSettingsBody extends ConsumerWidget {
  const _PrototypeSettingsBody({
    required this.settings,
    required this.user,
    required this.goals,
    required this.recurringIncomes,
    required this.profileService,
  });

  final UserSettings settings;
  final User? user;
  final List<dynamic> goals;
  final List<dynamic> recurringIncomes;
  final ProfileService profileService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(settingsRepositoryProvider);
    final displayName = profileService.displayName(user);
    final initials = profileService.initials(user);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 120),
      children: [
        _PrototypeSettingsHeader(),
        const SizedBox(height: 18),
        _PrototypeProfileCard(
          initials: initials,
          displayName: displayName.isEmpty ? 'Leko user' : displayName,
          email: user?.email ?? 'Signed out',
        ),
        const SizedBox(height: 16),
        _PrototypeSettingsGroup(
          title: 'PREMIUM',
          children: [
            _PrototypeSettingsRow(
              icon: Icons.workspace_premium_rounded,
              title: 'Leko Premium',
              subtitle: 'Subscriptions, bank review, OCR, voice, reports',
              isLast: true,
              onTap: () => context.push('/premium'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PrototypeSettingsGroup(
          title: 'ACCOUNT',
          children: [
            _PrototypeSettingsRow(
              icon: Icons.mail_outline_rounded,
              title: 'Email and login',
              subtitle: 'Password, sign-in, recovery',
              onTap: () => _showComingSoon(context, 'Email and login'),
            ),
            _PrototypeSettingsRow(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Bills, check-ins, reminders',
              onTap:
                  () => _showNotificationSettingsSheet(
                    context,
                    settings: settings,
                    repo: repo,
                  ),
            ),
            _PrototypeSettingsRow(
              icon: Icons.account_balance_rounded,
              title: 'Connections and imports',
              subtitle: 'Bank drafts, alerts, receipts, review queue',
              onTap: () => context.push('/imports'),
            ),
            _PrototypeSettingsRow(
              icon: Icons.group_outlined,
              title: 'Household mode',
              subtitle: 'Shared budgets, roles, and consent',
              onTap: () => context.push('/household'),
            ),
            _PrototypeSettingsRow(
              icon: Icons.paid_outlined,
              title: 'Budget preferences',
              subtitle: 'Default budget and categories',
              isLast: true,
              onTap:
                  () => _showChoiceSheet<AllowanceMode>(
                    context,
                    title: 'Default allowance mode',
                    value: settings.allowanceDefaultMode,
                    items: AllowanceMode.values,
                    labelOf: _allowanceModeLabel,
                    subtitleOf:
                        (value) => switch (value) {
                          AllowanceMode.paycheck =>
                            'Plan to the next cycle or payday',
                          AllowanceMode.goal => 'Plan around your primary goal',
                        },
                    onSelected:
                        (value) => saveSettingsField(
                          repo,
                          allowanceDefaultMode: value,
                        ),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PaychecksGroup(
          autoDepositEnabled:
              settings.defaultPaydayBehavior == PaydayBehavior.autoPostExpected,
          incomes: recurringIncomes.cast<RecurringIncome>(),
          onToggleAutoDeposit: (enabled) {
            saveSettingsField(
              repo,
              defaultPaydayBehavior:
                  enabled
                      ? PaydayBehavior.autoPostExpected
                      : PaydayBehavior.confirmActualOnPayday,
            );
            _applyAutoDepositToAllIncomes(
              ref,
              recurringIncomes.cast<RecurringIncome>(),
              enabled,
            );
          },
          onEditIncome: (income) => _showIncomeFormSheet(context, income),
          onAddIncome: () => _showIncomeFormSheet(context, null),
        ),
        const SizedBox(height: 16),
        _PrototypeSettingsGroup(
          title: 'APP',
          children: [
            _PrototypeSettingsRow(
              icon: Icons.schedule_rounded,
              title: 'Reminders',
              subtitle: 'Timing and frequency',
              onTap:
                  () => _showTimePickerRow(
                    context,
                    initialValue: settings.nightlyCloseoutTime,
                    onSelected:
                        (value) =>
                            saveSettingsField(repo, nightlyCloseoutTime: value),
                  ),
            ),
            _PrototypeSettingsRow(
              icon: Icons.shield_outlined,
              title: 'Security and privacy',
              subtitle: 'Data settings and protection',
              onTap: () => _showComingSoon(context, 'Security and privacy'),
            ),
            _PrototypeSettingsRow(
              icon: Icons.fullscreen_rounded,
              title: 'Export data',
              subtitle: 'CSV, summaries, and reports',
              onTap: () => _showComingSoon(context, 'Export data'),
            ),
            _PrototypeSettingsRow(
              icon: Icons.help_outline_rounded,
              title: 'Help and support',
              subtitle: 'Get help or send feedback',
              isLast: true,
              onTap: () => _showComingSoon(context, 'Help and support'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PrototypeAppearanceGroup(enabled: false, onToggle: (_) {}),
        const SizedBox(height: 16),
        _PrototypeSignOutCard(
          onTap: user == null ? null : () => _logout(context, ref),
        ),
      ],
    );
  }
}

void _showIncomeFormSheet(BuildContext context, RecurringIncome? existing) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => RecurringIncomeFormSheet(existing: existing),
  );
}

Future<void> _showNotificationSettingsSheet(
  BuildContext context, {
  required UserSettings settings,
  required SettingsRepository repo,
}) async {
  var paydayEnabled = settings.paydayEnabled;
  var billsEnabled = settings.billsEnabled;
  var overspendEnabled = settings.overspendEnabled;
  var cycleResetEnabled = settings.cycleResetEnabled;
  var nightlyCloseoutEnabled = settings.nightlyCloseoutEnabled;
  var nightlyCloseoutTime = settings.nightlyCloseoutTime;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: _SettingsReferencePalette.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _SettingsReferencePalette.chevron.withValues(
                            alpha: 0.7,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Notifications',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _SettingsReferencePalette.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose which reminders Leko can surface.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _SettingsReferencePalette.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PrototypeSettingsGroup(
                      title: 'REMINDERS',
                      children: [
                        _PrototypeToggleRow(
                          icon: Icons.payments_rounded,
                          title: 'Payday reminders',
                          subtitle: 'Income due and confirmation nudges',
                          value: paydayEnabled,
                          onChanged: (value) {
                            setSheetState(() => paydayEnabled = value);
                            saveSettingsField(repo, paydayEnabled: value);
                          },
                        ),
                        _PrototypeToggleRow(
                          icon: Icons.receipt_long_rounded,
                          title: 'Bill reminders',
                          subtitle: 'Upcoming bill alerts before they hit',
                          value: billsEnabled,
                          onChanged: (value) {
                            setSheetState(() => billsEnabled = value);
                            saveSettingsField(repo, billsEnabled: value);
                          },
                        ),
                        _PrototypeToggleRow(
                          icon: Icons.warning_amber_rounded,
                          title: 'Overspend alerts',
                          subtitle: 'Warnings when spending runs hot',
                          value: overspendEnabled,
                          onChanged: (value) {
                            setSheetState(() => overspendEnabled = value);
                            saveSettingsField(repo, overspendEnabled: value);
                          },
                        ),
                        _PrototypeToggleRow(
                          icon: Icons.restart_alt_rounded,
                          title: 'Cycle reset alerts',
                          subtitle: 'New allowance cycle reminders',
                          value: cycleResetEnabled,
                          onChanged: (value) {
                            setSheetState(() => cycleResetEnabled = value);
                            saveSettingsField(repo, cycleResetEnabled: value);
                          },
                        ),
                        _PrototypeToggleRow(
                          icon: Icons.nightlight_round,
                          title: 'Nightly closeout',
                          subtitle: 'End-of-day check-in prompt',
                          value: nightlyCloseoutEnabled,
                          isLast: !nightlyCloseoutEnabled,
                          onChanged: (value) {
                            setSheetState(() => nightlyCloseoutEnabled = value);
                            saveSettingsField(
                              repo,
                              nightlyCloseoutEnabled: value,
                            );
                          },
                        ),
                        if (nightlyCloseoutEnabled)
                          _PrototypeSettingsRow(
                            icon: Icons.schedule_rounded,
                            title: 'Closeout time',
                            subtitle: _formatTime(nightlyCloseoutTime),
                            isLast: true,
                            onTap:
                                () => _showTimePickerRow(
                                  context,
                                  initialValue: nightlyCloseoutTime,
                                  onSelected: (value) {
                                    setSheetState(
                                      () => nightlyCloseoutTime = value,
                                    );
                                    saveSettingsField(
                                      repo,
                                      nightlyCloseoutTime: value,
                                    );
                                  },
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _applyAutoDepositToAllIncomes(
  WidgetRef ref,
  List<RecurringIncome> incomes,
  bool enabled,
) async {
  if (incomes.isEmpty) return;
  final service = ref.read(recurringIncomeServiceProvider);
  final newBehavior =
      enabled
          ? PaydayBehavior.autoPostExpected
          : PaydayBehavior.confirmActualOnPayday;
  for (final income in incomes) {
    final current = enumFromDb<PaydayBehavior>(
      income.paydayBehavior,
      PaydayBehavior.values,
    );
    if (current == newBehavior) continue;
    if (enabled &&
        (income.expectedAmount == null || income.expectedAmount! <= 0)) {
      // Auto-deposit needs an expected amount; leave this one alone.
      continue;
    }
    await service.update(
      id: income.id,
      name: income.name,
      frequency: enumFromDb<IncomeFrequency>(
        income.frequency,
        IncomeFrequency.values,
      ),
      nextPaydayDate: income.nextPaydayDate,
      expectedAmount: income.expectedAmount,
      paydayBehavior: newBehavior,
    );
  }
}

class _PaychecksGroup extends StatelessWidget {
  const _PaychecksGroup({
    required this.autoDepositEnabled,
    required this.incomes,
    required this.onToggleAutoDeposit,
    required this.onEditIncome,
    required this.onAddIncome,
  });

  final bool autoDepositEnabled;
  final List<RecurringIncome> incomes;
  final ValueChanged<bool> onToggleAutoDeposit;
  final ValueChanged<RecurringIncome> onEditIncome;
  final VoidCallback onAddIncome;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'PAYCHECKS',
                    style: TextStyle(
                      color: _SettingsReferencePalette.label,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                if (incomes.isNotEmpty)
                  Text(
                    '${incomes.length} active',
                    style: const TextStyle(
                      color: _SettingsReferencePalette.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _PrototypeToggleRow(
            icon: Icons.savings_outlined,
            title: 'Auto-deposit on payday',
            subtitle:
                autoDepositEnabled
                    ? 'Leko will deposit each paycheck on its payday.'
                    : 'Leko will wait for you to confirm each paycheck.',
            value: autoDepositEnabled,
            onChanged: onToggleAutoDeposit,
            isLast: incomes.isEmpty,
          ),
          if (incomes.isNotEmpty) ...[
            for (var i = 0; i < incomes.length; i++)
              _PaycheckTile(
                income: incomes[i],
                onTap: () => onEditIncome(incomes[i]),
              ),
          ],
          _PrototypeSettingsRow(
            icon: Icons.add_rounded,
            title: incomes.isEmpty ? 'Add a paycheck' : 'Add another paycheck',
            subtitle:
                incomes.isEmpty
                    ? 'Set the amount and the days you get paid'
                    : 'Track another recurring deposit',
            isLast: true,
            onTap: onAddIncome,
          ),
        ],
      ),
    );
  }
}

class _PaycheckTile extends StatelessWidget {
  const _PaycheckTile({required this.income, required this.onTap});

  final RecurringIncome income;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amount = income.expectedAmount;
    final amountLabel =
        amount == null ? 'Amount not set' : '\$${amount.toStringAsFixed(2)}';
    final freq = enumFromDb<IncomeFrequency>(
      income.frequency,
      IncomeFrequency.values,
    );
    final cadence = switch (freq) {
      IncomeFrequency.weekly => 'every week',
      IncomeFrequency.biweekly => 'every 2 weeks',
      IncomeFrequency.monthly => 'every month',
    };
    final nextLabel = DateFormat.MMMd().format(income.nextPaydayDate);
    final behavior = enumFromDb<PaydayBehavior>(
      income.paydayBehavior,
      PaydayBehavior.values,
    );
    final autoOn = behavior == PaydayBehavior.autoPostExpected;
    final subtitle =
        '$amountLabel · $cadence · next $nextLabel${autoOn ? ' · Auto' : ''}';
    return _PrototypeSettingsRow(
      icon: Icons.payments_outlined,
      title: income.name,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}

class _PrototypeToggleRow extends StatelessWidget {
  const _PrototypeToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 4,
        right: 4,
        top: 10,
        bottom: isLast ? 10 : 16,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: _SettingsReferencePalette.iconCircle,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _SettingsReferencePalette.iconAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _SettingsReferencePalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _SettingsReferencePalette.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: _SettingsReferencePalette.navy,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFDCE7F7),
          ),
        ],
      ),
    );
  }
}

class _PrototypeSettingsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: _SettingsReferencePalette.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Make Leko work the way you want.',
                style: TextStyle(
                  color: _SettingsReferencePalette.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: _SettingsReferencePalette.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrototypeProfileCard extends StatelessWidget {
  const _PrototypeProfileCard({
    required this.initials,
    required this.displayName,
    required this.email,
  });

  final String initials;
  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: _SettingsReferencePalette.navy,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: _SettingsReferencePalette.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: _SettingsReferencePalette.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrototypeSettingsGroup extends StatelessWidget {
  const _PrototypeSettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              title,
              style: const TextStyle(
                color: _SettingsReferencePalette.label,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _PrototypeSettingsRow extends StatelessWidget {
  const _PrototypeSettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: EdgeInsets.only(
            left: 4,
            right: 4,
            top: 10,
            bottom: isLast ? 10 : 16,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: _SettingsReferencePalette.iconCircle,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: _SettingsReferencePalette.iconAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _SettingsReferencePalette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _SettingsReferencePalette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: _SettingsReferencePalette.chevron,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrototypeAppearanceGroup extends StatelessWidget {
  const _PrototypeAppearanceGroup({
    required this.enabled,
    required this.onToggle,
  });

  final bool enabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'APPEARANCE',
              style: TextStyle(
                color: _SettingsReferencePalette.label,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: _SettingsReferencePalette.iconCircle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.dark_mode_outlined,
                    color: _SettingsReferencePalette.iconAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dark mode',
                        style: TextStyle(
                          color: _SettingsReferencePalette.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Coming soon',
                        style: TextStyle(
                          color: _SettingsReferencePalette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                  activeColor: Colors.white,
                  activeTrackColor: _SettingsReferencePalette.navy,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFDCE7F7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrototypeSignOutCard extends StatelessWidget {
  const _PrototypeSignOutCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: _SettingsReferencePalette.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign out',
                      style: TextStyle(
                        color: _SettingsReferencePalette.danger,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'You can sign back in anytime',
                      style: TextStyle(
                        color: _SettingsReferencePalette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _SettingsReferencePalette {
  static const background = Color(0xFFF5F7FB);
  static const navy = Color(0xFF132440);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const label = Color(0xFF94A3B8);
  static const iconCircle = Color(0xFFF1F5F9);
  static const iconAccent = Color(0xFF475569);
  static const chevron = Color(0xFF94A3B8);
  static const danger = Color(0xFFE11D48);
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({
    required this.settings,
    required this.user,
    required this.goals,
    required this.recurringIncomes,
    required this.profileService,
  });

  final UserSettings settings;
  final User? user;
  final List<dynamic> goals;
  final List<dynamic> recurringIncomes;
  final ProfileService profileService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(settingsRepositoryProvider);
    final displayName = profileService.displayName(user);
    final firstName = profileService.firstName(user);
    final initials = profileService.initials(user);
    final isGoalMode = settings.allowanceDefaultMode == AllowanceMode.goal;
    final isPaydayBased =
        settings.rolloverResetType == RolloverResetType.paydayBased;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        _Header(name: firstName),
        const SizedBox(height: 22),
        _ProfileHero(
          user: user,
          displayName: displayName,
          initials: initials,
          currency: settings.baseCurrency,
          planningSummary:
              '${_allowanceModeLabel(settings.allowanceDefaultMode)} mode · ${_rolloverLabel(settings.rolloverResetType)} cycle',
          onEditName: () => _showEditNameSheet(context, ref, displayName),
          onEditCurrency:
              () => _showChoiceSheet<Currency>(
                context,
                title: 'Preferred currency',
                value: settings.baseCurrency,
                items: Currency.values,
                labelOf: (value) => value.name.toUpperCase(),
                subtitleOf:
                    (value) => switch (value) {
                      Currency.cad => 'Use Canadian dollars across the app',
                      Currency.usd => 'Use US dollars across the app',
                    },
                onSelected:
                    (value) => saveSettingsField(repo, baseCurrency: value),
              ),
        ),
        const SizedBox(height: 18),
        _SectionTitle(
          title: 'Profile',
          subtitle:
              'Your identity and the money language Leko uses everywhere.',
        ),
        const SizedBox(height: 10),
        _SettingsGroup(
          children: [
            _SettingsRow(
              icon: Icons.badge_rounded,
              title: 'Name',
              subtitle: 'How Leko should address you',
              value: displayName.isEmpty ? 'Add name' : displayName,
              onTap: () => _showEditNameSheet(context, ref, displayName),
            ),
            _SettingsRow(
              icon: Icons.mail_outline_rounded,
              title: 'Email',
              subtitle: 'Your sign-in account',
              value: user?.email ?? 'Signed out',
            ),
            _SettingsRow(
              icon: Icons.attach_money_rounded,
              title: 'Preferred currency',
              subtitle: 'How balances and budgets are displayed',
              value: settings.baseCurrency.name.toUpperCase(),
              isLast: true,
              onTap:
                  () => _showChoiceSheet<Currency>(
                    context,
                    title: 'Preferred currency',
                    value: settings.baseCurrency,
                    items: Currency.values,
                    labelOf: (value) => value.name.toUpperCase(),
                    subtitleOf:
                        (value) => switch (value) {
                          Currency.cad => 'Use Canadian dollars across the app',
                          Currency.usd => 'Use US dollars across the app',
                        },
                    onSelected:
                        (value) => saveSettingsField(repo, baseCurrency: value),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionTitle(
          title: 'Budgeting',
          subtitle:
              'The controls that shape your allowance, planning rhythm, and goal focus.',
        ),
        const SizedBox(height: 10),
        if (isGoalMode || isPaydayBased) ...[
          _PlanningHighlight(
            icon: isGoalMode ? Icons.flag_circle_rounded : Icons.anchor_rounded,
            eyebrow:
                isGoalMode
                    ? 'Goal planning is active'
                    : 'Payday cycle is active',
            title:
                isGoalMode
                    ? _goalName(settings.primaryGoalId)
                    : _anchorName(settings.paydayAnchorRecurringIncomeId),
            subtitle:
                isGoalMode
                    ? 'Primary goal is directly shaping your default allowance mode.'
                    : 'Payday anchor is defining when allowance cycles reset.',
          ),
          const SizedBox(height: 12),
        ],
        _SettingsGroup(
          children: [
            _SettingsRow(
              icon: Icons.space_dashboard_rounded,
              title: 'Default allowance mode',
              subtitle: 'Choose the planning lens Leko should prioritize',
              value: _allowanceModeLabel(settings.allowanceDefaultMode),
              onTap:
                  () => _showChoiceSheet<AllowanceMode>(
                    context,
                    title: 'Default allowance mode',
                    value: settings.allowanceDefaultMode,
                    items: AllowanceMode.values,
                    labelOf: _allowanceModeLabel,
                    subtitleOf:
                        (value) => switch (value) {
                          AllowanceMode.paycheck =>
                            'Plan to the next cycle or payday',
                          AllowanceMode.goal => 'Plan around your primary goal',
                        },
                    onSelected:
                        (value) => saveSettingsField(
                          repo,
                          allowanceDefaultMode: value,
                        ),
                  ),
            ),
            _SettingsRow(
              icon: Icons.insights_rounded,
              title: 'Spending baseline',
              subtitle: 'How much recent history should shape guidance',
              value: '${settings.spendingBaselineDays} days',
              onTap:
                  () => _showChoiceSheet<int>(
                    context,
                    title: 'Spending baseline',
                    value: settings.spendingBaselineDays,
                    items: const [30, 60, 90],
                    labelOf: (value) => '$value days',
                    subtitleOf:
                        (value) => switch (value) {
                          30 => 'More responsive to recent changes',
                          60 => 'Balanced for most people',
                          _ => 'Smoother and less jumpy',
                        },
                    onSelected:
                        (value) => saveSettingsField(
                          repo,
                          spendingBaselineDays: value,
                        ),
                  ),
            ),
            _SettingsRow(
              icon: Icons.event_repeat_rounded,
              title: 'Cycle reset',
              subtitle: 'When allowance planning should refresh',
              value: _rolloverLabel(settings.rolloverResetType),
              onTap:
                  () => _showChoiceSheet<RolloverResetType>(
                    context,
                    title: 'Cycle reset',
                    value: settings.rolloverResetType,
                    items: RolloverResetType.values,
                    labelOf: _rolloverLabel,
                    subtitleOf:
                        (value) => switch (value) {
                          RolloverResetType.monthly =>
                            'Reset on a clean monthly rhythm',
                          RolloverResetType.paydayBased =>
                            'Reset around your payday schedule',
                        },
                    onSelected:
                        (value) =>
                            saveSettingsField(repo, rolloverResetType: value),
                  ),
            ),
            _SettingsRow(
              icon: Icons.payments_rounded,
              title: 'Default payday behavior',
              subtitle: 'How recurring income should post by default',
              value: _paydayBehaviorLabel(settings.defaultPaydayBehavior),
              onTap:
                  () => _showChoiceSheet<PaydayBehavior>(
                    context,
                    title: 'Default payday behavior',
                    value: settings.defaultPaydayBehavior,
                    items: PaydayBehavior.values,
                    labelOf: _paydayBehaviorLabel,
                    subtitleOf:
                        (value) => switch (value) {
                          PaydayBehavior.confirmActualOnPayday =>
                            'Wait for you to confirm the real amount',
                          PaydayBehavior.autoPostExpected =>
                            'Automatically post the expected amount',
                        },
                    onSelected:
                        (value) => saveSettingsField(
                          repo,
                          defaultPaydayBehavior: value,
                        ),
                  ),
            ),
            _SettingsRow(
              icon: Icons.flag_circle_rounded,
              title: 'Primary goal',
              subtitle:
                  settings.allowanceDefaultMode == AllowanceMode.goal
                      ? 'This is front and center in your goal-based allowance'
                      : 'Choose the goal Leko should keep in view',
              value: _goalName(settings.primaryGoalId),
              emphasis: isGoalMode,
              onTap:
                  () => _showChoiceSheet<String?>(
                    context,
                    title: 'Primary goal',
                    value: settings.primaryGoalId,
                    items: [null, ...goals.map((goal) => goal.id as String)],
                    labelOf:
                        (value) => value == null ? 'None' : _goalName(value),
                    subtitleOf:
                        (value) =>
                            value == null
                                ? 'No goal will be prioritized'
                                : 'Use this goal as the main planning focus',
                    onSelected:
                        (value) =>
                            saveSettingsField(repo, primaryGoalId: () => value),
                  ),
            ),
            if (settings.rolloverResetType == RolloverResetType.paydayBased)
              _SettingsRow(
                icon: Icons.anchor_rounded,
                title: 'Payday anchor',
                subtitle: 'The recurring income that defines your cycle timing',
                value: _anchorName(settings.paydayAnchorRecurringIncomeId),
                emphasis: true,
                onTap:
                    () => _showChoiceSheet<String?>(
                      context,
                      title: 'Payday anchor',
                      value: settings.paydayAnchorRecurringIncomeId,
                      items: [
                        null,
                        ...recurringIncomes.map(
                          (income) => income.id as String,
                        ),
                      ],
                      labelOf:
                          (value) =>
                              value == null ? 'None' : _anchorName(value),
                      subtitleOf:
                          (value) =>
                              value == null
                                  ? 'Payday-based planning needs an anchor income'
                                  : 'Use this income to anchor payday cycles',
                      onSelected:
                          (value) => saveSettingsField(
                            repo,
                            paydayAnchorRecurringIncomeId: () => value,
                          ),
                    ),
              ),
            _SettingsRow(
              icon: Icons.sync_alt_rounded,
              title: 'Reconcile balance',
              subtitle: 'Align Leko with your real bank balance',
              value: 'Adjust now',
              isLast: true,
              onTap:
                  () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const ReconcileSheet(),
                  ),
            ),
          ],
        ),
        if (settings.allowanceDefaultMode == AllowanceMode.goal &&
            settings.primaryGoalId == null) ...[
          const SizedBox(height: 12),
          const _ContextCard(
            icon: Icons.flag_circle_rounded,
            text:
                'Goal mode works best when you choose a primary goal. Leko can only plan toward what it knows matters most.',
          ),
        ],
        if (settings.rolloverResetType == RolloverResetType.paydayBased &&
            settings.paydayAnchorRecurringIncomeId == null) ...[
          const SizedBox(height: 12),
          const _ContextCard(
            icon: Icons.anchor_rounded,
            text:
                'Payday-based reset needs an anchor recurring income so the cycle has a real schedule to follow.',
          ),
        ],
        const SizedBox(height: 20),
        _SectionTitle(
          title: 'Notifications',
          subtitle:
              'Calm reminders for payday, bills, overspend recovery, and nightly closeout.',
        ),
        const SizedBox(height: 10),
        _SettingsGroup(
          children: [
            _ToggleSettingsRow(
              icon: Icons.payments_rounded,
              title: 'Payday reminders',
              subtitle: 'Get nudged when income is due or confirmed',
              value: settings.paydayEnabled,
              onChanged:
                  (value) => saveSettingsField(repo, paydayEnabled: value),
            ),
            _ToggleSettingsRow(
              icon: Icons.receipt_long_rounded,
              title: 'Bill reminders',
              subtitle: 'Surface upcoming bills before they hit',
              value: settings.billsEnabled,
              onChanged:
                  (value) => saveSettingsField(repo, billsEnabled: value),
            ),
            _ToggleSettingsRow(
              icon: Icons.warning_amber_rounded,
              title: 'Overspend alerts',
              subtitle: 'Catch drift quickly when today runs too hot',
              value: settings.overspendEnabled,
              accentColor: _SettingsPalette.alert,
              onChanged:
                  (value) => saveSettingsField(repo, overspendEnabled: value),
            ),
            _ToggleSettingsRow(
              icon: Icons.restart_alt_rounded,
              title: 'Cycle reset alerts',
              subtitle: 'Know when a new allowance cycle begins',
              value: settings.cycleResetEnabled,
              onChanged:
                  (value) => saveSettingsField(repo, cycleResetEnabled: value),
            ),
            _ToggleSettingsRow(
              icon: Icons.nightlight_round,
              title: 'Nightly closeout',
              subtitle:
                  'Keep the daily habit alive with a calm end-of-day prompt',
              value: settings.nightlyCloseoutEnabled,
              isLast: !settings.nightlyCloseoutEnabled,
              onChanged:
                  (value) =>
                      saveSettingsField(repo, nightlyCloseoutEnabled: value),
            ),
            if (settings.nightlyCloseoutEnabled)
              _SettingsRow(
                icon: Icons.schedule_rounded,
                title: 'Nightly closeout time',
                subtitle: 'When Leko should ask you to wrap the day',
                value: _formatTime(settings.nightlyCloseoutTime),
                isLast: true,
                onTap:
                    () => _showTimePickerRow(
                      context,
                      initialValue: settings.nightlyCloseoutTime,
                      onSelected:
                          (value) => saveSettingsField(
                            repo,
                            nightlyCloseoutTime: value,
                          ),
                    ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionTitle(
          title: 'Support and account',
          subtitle: 'Policies, help, and account actions when you need them.',
        ),
        const SizedBox(height: 10),
        _SettingsGroup(
          children: [
            _SettingsRow(
              icon: Icons.help_outline_rounded,
              title: 'Help and support',
              subtitle: 'Get unstuck or contact the team',
              value: 'Open',
              onTap: () => _showComingSoon(context, 'Help and support'),
            ),
            _SettingsRow(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy',
              subtitle: 'Read how your data is handled',
              value: 'View',
              onTap:
                  () => _showPolicySheet(
                    context,
                    title: 'Privacy',
                    sections: _privacySections,
                  ),
            ),
            _SettingsRow(
              icon: Icons.gavel_rounded,
              title: 'Terms',
              subtitle: 'Read the terms for using Leko',
              value: 'View',
              onTap:
                  () => _showPolicySheet(
                    context,
                    title: 'Terms',
                    sections: _termsSections,
                  ),
            ),
            _SettingsRow(
              icon: Icons.logout_rounded,
              title: 'Sign out',
              subtitle: 'Leave this device and return to welcome',
              value: 'Sign out',
              valueColor: _SettingsPalette.alert,
              iconColor: _SettingsPalette.alert,
              isLast: true,
              onTap: user == null ? null : () => _logout(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  String _goalName(String? id) {
    if (id == null) return goals.isEmpty ? 'No goals yet' : 'None';
    for (final goal in goals) {
      if (goal.id == id) return goal.name as String;
    }
    return 'Unknown goal';
  }

  String _anchorName(String? id) {
    if (id == null) {
      return recurringIncomes.isEmpty ? 'No recurring income yet' : 'None';
    }
    for (final income in recurringIncomes) {
      if (income.id == id) return income.name as String;
    }
    return 'Unknown income';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings_outlined,
                color: _SettingsPalette.textMuted,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Planning setup',
                style: TextStyle(
                  color: _SettingsPalette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: _SettingsPalette.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name.isEmpty
              ? 'Your account and money control center.'
              : 'Your account and money control center, $name.',
          style: const TextStyle(
            color: _SettingsPalette.textSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.displayName,
    required this.initials,
    required this.currency,
    required this.planningSummary,
    required this.onEditName,
    required this.onEditCurrency,
  });

  final User? user;
  final String displayName;
  final String initials;
  final Currency currency;
  final String planningSummary;
  final VoidCallback onEditName;
  final VoidCallback onEditCurrency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _SettingsPalette.surface,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: _SettingsPalette.outlineStrong),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: _SettingsPalette.teal.withValues(alpha: 0.08),
            blurRadius: 34,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'BUDGETING PROFILE',
                  style: TextStyle(
                    color: _SettingsPalette.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _SettingsPalette.surfaceSoft,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: _SettingsPalette.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName.isEmpty ? 'Leko user' : displayName,
                      style: const TextStyle(
                        color: _SettingsPalette.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'Signed out',
                      style: const TextStyle(
                        color: _SettingsPalette.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your planning setup',
                        style: TextStyle(
                          color: _SettingsPalette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        planningSummary,
                        style: const TextStyle(
                          color: _SettingsPalette.textSoft,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(
                label: currency.name.toUpperCase(),
                icon: Icons.attach_money_rounded,
                onTap: onEditCurrency,
              ),
              const SizedBox(width: 10),
              _HeroChip(
                label: 'Edit name',
                icon: Icons.edit_rounded,
                onTap: onEditName,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: _SettingsPalette.textSoft),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: _SettingsPalette.textSoft,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _SettingsPalette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _SettingsPalette.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _SettingsPalette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _SettingsPalette.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onTap,
    this.isLast = false,
    this.iconColor,
    this.valueColor,
    this.emphasis = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback? onTap;
  final bool isLast;
  final Color? iconColor;
  final Color? valueColor;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  emphasis
                      ? _SettingsPalette.teal.withValues(alpha: 0.18)
                      : (iconColor ?? _SettingsPalette.iconMuted).withValues(
                        alpha: 0.12,
                      ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 20,
              color:
                  emphasis
                      ? _SettingsPalette.tealBright
                      : iconColor ?? _SettingsPalette.iconMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _SettingsPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _SettingsPalette.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color:
                    valueColor ??
                    (emphasis
                        ? _SettingsPalette.textSoft
                        : _SettingsPalette.textMuted),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: _SettingsPalette.textMuted,
            ),
          ],
        ],
      ),
    );

    final child =
        onTap == null
            ? row
            : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius:
                    isLast
                        ? const BorderRadius.vertical(
                          bottom: Radius.circular(28),
                        )
                        : null,
                child: row,
              ),
            );

    return Column(
      children: [
        child,
        if (!isLast)
          const Divider(
            height: 1,
            indent: 74,
            endIndent: 18,
            color: _SettingsPalette.divider,
          ),
      ],
    );
  }
}

class _ToggleSettingsRow extends StatelessWidget {
  const _ToggleSettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.accentColor,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accentColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? _SettingsPalette.teal;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _SettingsPalette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _SettingsPalette.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Switch.adaptive(
                value: value,
                activeColor: color,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 74,
            endIndent: 18,
            color: _SettingsPalette.divider,
          ),
      ],
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SettingsPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _SettingsPalette.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _SettingsPalette.teal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _SettingsPalette.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanningHighlight extends StatelessWidget {
  const _PlanningHighlight({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _SettingsPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _SettingsPalette.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _SettingsPalette.teal.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _SettingsPalette.tealBright, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: _SettingsPalette.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: _SettingsPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _SettingsPalette.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsBackdrop extends StatelessWidget {
  const _SettingsBackdrop();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _SettingsPalette.background,
      child: SizedBox.expand(),
    );
  }
}

Future<void> _showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required T value,
  required List<T> items,
  required String Function(T) labelOf,
  String Function(T)? subtitleOf,
  required ValueChanged<T> onSelected,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: _SettingsPalette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _SettingsPalette.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: _SettingsPalette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item == value;
                    return Material(
                      color:
                          isSelected
                              ? _SettingsPalette.surfaceSoft
                              : _SettingsPalette.backgroundSoft,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          onSelected(item);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      labelOf(item),
                                      style: const TextStyle(
                                        color: _SettingsPalette.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (subtitleOf != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitleOf(item),
                                        style: const TextStyle(
                                          color: _SettingsPalette.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color:
                                    isSelected
                                        ? _SettingsPalette.teal
                                        : _SettingsPalette.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showEditNameSheet(
  BuildContext context,
  WidgetRef ref,
  String currentValue,
) async {
  final ctrl = TextEditingController(text: currentValue);
  var isSaving = false;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final valid = ctrl.text.trim().isNotEmpty;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: const BoxDecoration(
                color: _SettingsPalette.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _SettingsPalette.textMuted.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Edit name',
                      style: TextStyle(
                        color: _SettingsPalette.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ctrl,
                      textCapitalization: TextCapitalization.words,
                      autofocus: true,
                      style: const TextStyle(
                        color: _SettingsPalette.textPrimary,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'First name',
                        hintStyle: const TextStyle(
                          color: _SettingsPalette.textMuted,
                        ),
                        filled: true,
                        fillColor: _SettingsPalette.backgroundSoft,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: _SettingsPalette.outline,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: _SettingsPalette.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: _SettingsPalette.teal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _SettingsPalette.teal,
                          foregroundColor: _SettingsPalette.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed:
                            !valid || isSaving
                                ? null
                                : () async {
                                  setState(() => isSaving = true);
                                  try {
                                    await ref
                                        .read(profileServiceProvider)
                                        .updateDisplayName(ctrl.text);
                                    if (context.mounted) Navigator.pop(context);
                                  } finally {
                                    if (context.mounted) {
                                      setState(() => isSaving = false);
                                    }
                                  }
                                },
                        child:
                            isSaving
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _SettingsPalette.textPrimary,
                                  ),
                                )
                                : const Text(
                                  'Save name',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showTimePickerRow(
  BuildContext context, {
  required String initialValue,
  required ValueChanged<String> onSelected,
}) async {
  final initial = _parseTime(initialValue);
  final picked = await showTimePicker(context: context, initialTime: initial);
  if (picked != null) {
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    onSelected(value);
  }
}

void _showComingSoon(BuildContext context, String label) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$label link can be wired next.')));
}

void _showPolicySheet(
  BuildContext context, {
  required String title,
  required List<({String heading, String body})> sections,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.42,
        maxChildSize: 0.92,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _SettingsPalette.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final section in sections) ...[
                  const SizedBox(height: 16),
                  Text(
                    section.heading,
                    style: const TextStyle(
                      color: _SettingsPalette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    section.body,
                    style: const TextStyle(
                      color: _SettingsPalette.textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    },
  );
}

const _privacySections = <({String heading, String body})>[
  (
    heading: 'Financial data',
    body:
        'Leko uses your balances, income, expenses, bills, categories, and goals to calculate budgets and show insights. We only use this data to operate and improve your Leko experience.',
  ),
  (
    heading: 'Attachments',
    body:
        'Receipts, images, screenshots, and PDFs you attach in Leaf can be associated with the chat or transaction draft. Parsing may be added later to suggest amount, merchant, date, and category.',
  ),
  (
    heading: 'Notification reading',
    body:
        'Automatic expense detection from bank notifications must be opt-in. Leko should ask for permission first, store only the details needed to create transactions, and let you turn it off.',
  ),
  (
    heading: 'Bank connections',
    body:
        'Bank connections are optional and use Flinks Connect. Leko does not receive your bank username or password. It stores encrypted connection identifiers, selected account metadata, balances, and transaction drafts needed for review. Disconnecting asks Flinks to delete linked bank data and removes unimported bank records from Leko.',
  ),
];

const _termsSections = <({String heading, String body})>[
  (
    heading: 'Budget guidance',
    body:
        'Leaf gives practical budgeting suggestions based on the information in your app. It is not a financial adviser and does not provide professional investment, tax, or legal advice.',
  ),
  (
    heading: 'User control',
    body:
        'You choose what to add, import, attach, or connect. Features such as notification reading and bank connections should remain optional and permission-based.',
  ),
  (
    heading: 'Accuracy',
    body:
        'Leko tries to keep math and transaction history accurate, but you should review important balances, bills, and imported transactions before relying on them.',
  ),
  (
    heading: 'Attachments and imports',
    body:
        'You are responsible for files you upload and accounts you connect. Do not upload documents you do not have permission to use.',
  ),
];

Future<void> _logout(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Sign out?'),
          content: const Text(
            'You will need to sign in again to access your budget.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _SettingsPalette.alert,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out'),
            ),
          ],
        ),
  );

  if (ok == true && context.mounted) {
    await ref.read(supabaseClientProvider).auth.signOut();
    if (context.mounted) context.go('/welcome');
  }
}

String _allowanceModeLabel(AllowanceMode value) => switch (value) {
  AllowanceMode.paycheck => 'Paycheck',
  AllowanceMode.goal => 'Goal',
};

String _rolloverLabel(RolloverResetType value) => switch (value) {
  RolloverResetType.monthly => 'Monthly',
  RolloverResetType.paydayBased => 'Payday based',
};

String _paydayBehaviorLabel(PaydayBehavior value) => switch (value) {
  PaydayBehavior.confirmActualOnPayday => 'Confirm actual',
  PaydayBehavior.autoPostExpected => 'Auto-post expected',
};

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return const TimeOfDay(hour: 21, minute: 0);
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 21,
    minute: int.tryParse(parts[1]) ?? 0,
  );
}

String _formatTime(String value) {
  final time = _parseTime(value);
  final now = DateTime.now();
  return DateFormat.jm().format(
    DateTime(now.year, now.month, now.day, time.hour, time.minute),
  );
}

abstract final class _SettingsPalette {
  static const background = Color(0xFF06090A);
  static const backgroundSoft = Color(0xFF0D1214);
  static const surface = Color(0xFF0F1416);
  static const surfaceSoft = Color(0xFF131A1C);
  static const textPrimary = Color(0xFFF7F3EC);
  static const textSecondary = Color(0xFFA6B2AF);
  static const textMuted = Color(0xFF738382);
  static const textSoft = Color(0xFFDDE9E4);
  static const teal = Color(0xFF2B827B);
  static const tealBright = Color(0xFF73D1BE);
  static const iconMuted = Color(0xFF8CA09D);
  static const outline = Color(0x22339D95);
  static const outlineStrong = Color(0x3348B9AE);
  static const divider = Color(0x18FFFFFF);
  static const alert = Color(0xFFD97C70);
}
