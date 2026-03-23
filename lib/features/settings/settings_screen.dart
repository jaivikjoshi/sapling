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
import '../../domain/models/enums.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/services/profile_service.dart';
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
      backgroundColor: _SettingsPalette.background,
      body: Stack(
        children: [
          const _SettingsBackdrop(),
          SafeArea(
            child: settingsAsync.when(
              data: (settings) => _SettingsBody(
                settings: settings,
                user: user,
                goals: goals,
                recurringIncomes: incomes,
                profileService: profileService,
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: _SettingsPalette.teal),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Settings failed to load.\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _SettingsPalette.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    final isPaydayBased = settings.rolloverResetType == RolloverResetType.paydayBased;

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
          onEditCurrency: () => _showChoiceSheet<Currency>(
            context,
            title: 'Preferred currency',
            value: settings.baseCurrency,
            items: Currency.values,
            labelOf: (value) => value.name.toUpperCase(),
            subtitleOf: (value) => switch (value) {
              Currency.cad => 'Use Canadian dollars across the app',
              Currency.usd => 'Use US dollars across the app',
            },
            onSelected: (value) => saveSettingsField(repo, baseCurrency: value),
          ),
        ),
        const SizedBox(height: 18),
        _SectionTitle(
          title: 'Profile',
          subtitle: 'Your identity and the money language Leko uses everywhere.',
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
              onTap: () => _showChoiceSheet<Currency>(
                context,
                title: 'Preferred currency',
                value: settings.baseCurrency,
                items: Currency.values,
                labelOf: (value) => value.name.toUpperCase(),
                subtitleOf: (value) => switch (value) {
                  Currency.cad => 'Use Canadian dollars across the app',
                  Currency.usd => 'Use US dollars across the app',
                },
                onSelected: (value) => saveSettingsField(repo, baseCurrency: value),
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
            eyebrow: isGoalMode ? 'Goal planning is active' : 'Payday cycle is active',
            title: isGoalMode
                ? _goalName(settings.primaryGoalId)
                : _anchorName(settings.paydayAnchorRecurringIncomeId),
            subtitle: isGoalMode
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
              onTap: () => _showChoiceSheet<AllowanceMode>(
                context,
                title: 'Default allowance mode',
                value: settings.allowanceDefaultMode,
                items: AllowanceMode.values,
                labelOf: _allowanceModeLabel,
                subtitleOf: (value) => switch (value) {
                  AllowanceMode.paycheck => 'Plan to the next cycle or payday',
                  AllowanceMode.goal => 'Plan around your primary goal',
                },
                onSelected: (value) =>
                    saveSettingsField(repo, allowanceDefaultMode: value),
              ),
            ),
            _SettingsRow(
              icon: Icons.insights_rounded,
              title: 'Spending baseline',
              subtitle: 'How much recent history should shape guidance',
              value: '${settings.spendingBaselineDays} days',
              onTap: () => _showChoiceSheet<int>(
                context,
                title: 'Spending baseline',
                value: settings.spendingBaselineDays,
                items: const [30, 60, 90],
                labelOf: (value) => '$value days',
                subtitleOf: (value) => switch (value) {
                  30 => 'More responsive to recent changes',
                  60 => 'Balanced for most people',
                  _ => 'Smoother and less jumpy',
                },
                onSelected: (value) =>
                    saveSettingsField(repo, spendingBaselineDays: value),
              ),
            ),
            _SettingsRow(
              icon: Icons.event_repeat_rounded,
              title: 'Cycle reset',
              subtitle: 'When allowance planning should refresh',
              value: _rolloverLabel(settings.rolloverResetType),
              onTap: () => _showChoiceSheet<RolloverResetType>(
                context,
                title: 'Cycle reset',
                value: settings.rolloverResetType,
                items: RolloverResetType.values,
                labelOf: _rolloverLabel,
                subtitleOf: (value) => switch (value) {
                  RolloverResetType.monthly => 'Reset on a clean monthly rhythm',
                  RolloverResetType.paydayBased => 'Reset around your payday schedule',
                },
                onSelected: (value) =>
                    saveSettingsField(repo, rolloverResetType: value),
              ),
            ),
            _SettingsRow(
              icon: Icons.payments_rounded,
              title: 'Default payday behavior',
              subtitle: 'How recurring income should post by default',
              value: _paydayBehaviorLabel(settings.defaultPaydayBehavior),
              onTap: () => _showChoiceSheet<PaydayBehavior>(
                context,
                title: 'Default payday behavior',
                value: settings.defaultPaydayBehavior,
                items: PaydayBehavior.values,
                labelOf: _paydayBehaviorLabel,
                subtitleOf: (value) => switch (value) {
                  PaydayBehavior.confirmActualOnPayday =>
                    'Wait for you to confirm the real amount',
                  PaydayBehavior.autoPostExpected =>
                    'Automatically post the expected amount',
                },
                onSelected: (value) =>
                    saveSettingsField(repo, defaultPaydayBehavior: value),
              ),
            ),
            _SettingsRow(
              icon: Icons.flag_circle_rounded,
              title: 'Primary goal',
              subtitle: settings.allowanceDefaultMode == AllowanceMode.goal
                  ? 'This is front and center in your goal-based allowance'
                  : 'Choose the goal Leko should keep in view',
              value: _goalName(settings.primaryGoalId),
              emphasis: isGoalMode,
              onTap: () => _showChoiceSheet<String?>(
                context,
                title: 'Primary goal',
                value: settings.primaryGoalId,
                items: [
                  null,
                  ...goals.map((goal) => goal.id as String),
                ],
                labelOf: (value) => value == null ? 'None' : _goalName(value),
                subtitleOf: (value) => value == null
                    ? 'No goal will be prioritized'
                    : 'Use this goal as the main planning focus',
                onSelected: (value) =>
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
                onTap: () => _showChoiceSheet<String?>(
                  context,
                  title: 'Payday anchor',
                  value: settings.paydayAnchorRecurringIncomeId,
                  items: [
                    null,
                    ...recurringIncomes.map((income) => income.id as String),
                  ],
                  labelOf: (value) =>
                      value == null ? 'None' : _anchorName(value),
                  subtitleOf: (value) => value == null
                      ? 'Payday-based planning needs an anchor income'
                      : 'Use this income to anchor payday cycles',
                  onSelected: (value) => saveSettingsField(
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
              onTap: () => showModalBottomSheet<void>(
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
              onChanged: (value) => saveSettingsField(repo, paydayEnabled: value),
            ),
            _ToggleSettingsRow(
              icon: Icons.receipt_long_rounded,
              title: 'Bill reminders',
              subtitle: 'Surface upcoming bills before they hit',
              value: settings.billsEnabled,
              onChanged: (value) => saveSettingsField(repo, billsEnabled: value),
            ),
            _ToggleSettingsRow(
              icon: Icons.warning_amber_rounded,
              title: 'Overspend alerts',
              subtitle: 'Catch drift quickly when today runs too hot',
              value: settings.overspendEnabled,
              accentColor: _SettingsPalette.alert,
              onChanged: (value) =>
                  saveSettingsField(repo, overspendEnabled: value),
            ),
            _ToggleSettingsRow(
              icon: Icons.restart_alt_rounded,
              title: 'Cycle reset alerts',
              subtitle: 'Know when a new allowance cycle begins',
              value: settings.cycleResetEnabled,
              onChanged: (value) =>
                  saveSettingsField(repo, cycleResetEnabled: value),
            ),
            _ToggleSettingsRow(
              icon: Icons.nightlight_round,
              title: 'Nightly closeout',
              subtitle: 'Keep the daily habit alive with a calm end-of-day prompt',
              value: settings.nightlyCloseoutEnabled,
              isLast: !settings.nightlyCloseoutEnabled,
              onChanged: (value) =>
                  saveSettingsField(repo, nightlyCloseoutEnabled: value),
            ),
            if (settings.nightlyCloseoutEnabled)
              _SettingsRow(
                icon: Icons.schedule_rounded,
                title: 'Nightly closeout time',
                subtitle: 'When Leko should ask you to wrap the day',
                value: _formatTime(settings.nightlyCloseoutTime),
                isLast: true,
                onTap: () => _showTimePickerRow(
                  context,
                  initialValue: settings.nightlyCloseoutTime,
                  onSelected: (value) =>
                      saveSettingsField(repo, nightlyCloseoutTime: value),
                ),
              )
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
              onTap: () => _showComingSoon(context, 'Privacy'),
            ),
            _SettingsRow(
              icon: Icons.gavel_rounded,
              title: 'Terms',
              subtitle: 'Read the terms for using Leko',
              value: 'View',
              onTap: () => _showComingSoon(context, 'Terms'),
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
                letterSpacing: -1.1,
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
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF121516),
            Color(0xFF1A2123),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A2B2C), Color(0xFF0E1719)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                        letterSpacing: -0.9,
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
            letterSpacing: -0.2,
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
              color: emphasis
                  ? _SettingsPalette.teal.withValues(alpha: 0.18)
                  : (iconColor ?? _SettingsPalette.iconMuted).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 20,
              color: emphasis
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
                color: valueColor ??
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

    final child = onTap == null
        ? row
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: isLast
                  ? const BorderRadius.vertical(bottom: Radius.circular(28))
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
    return Stack(
      children: [
        Container(color: _SettingsPalette.background),
        const Positioned(
          top: -120,
          right: -80,
          child: _BackdropOrb(size: 280, color: Color(0x1635A69D)),
        ),
        const Positioned(
          top: 260,
          left: -90,
          child: _BackdropOrb(size: 220, color: Color(0x0EE3BC88)),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.02),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
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
                      color: isSelected
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
                                color: isSelected
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
                        color: _SettingsPalette.textMuted.withValues(alpha: 0.35),
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
                      style: const TextStyle(color: _SettingsPalette.textPrimary),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'First name',
                        hintStyle:
                            const TextStyle(color: _SettingsPalette.textMuted),
                        filled: true,
                        fillColor: _SettingsPalette.backgroundSoft,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide:
                              const BorderSide(color: _SettingsPalette.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide:
                              const BorderSide(color: _SettingsPalette.outline),
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
                        onPressed: !valid || isSaving
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
                        child: isSaving
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
  final picked = await showTimePicker(
    context: context,
    initialTime: initial,
  );
  if (picked != null) {
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    onSelected(value);
  }
}

void _showComingSoon(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label link can be wired next.')),
  );
}

Future<void> _logout(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Sign out?'),
      content: const Text('You will need to sign in again to access your budget.'),
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
