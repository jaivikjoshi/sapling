import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/scheduler_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../widget_preview/widget_preview_screen.dart';
import '../../core/theme/sapling_colors.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/settings_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) => _SettingsBody(settings: settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});

  final UserSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(settingsRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _SectionHeader('General'),
        _InfoTile(
          icon: Icons.attach_money,
          title: 'Currency',
          value: settings.baseCurrency.name.toUpperCase(),
        ),
        _ChoiceTile<AllowanceMode>(
          icon: Icons.calculate_outlined,
          title: 'Default allowance mode',
          value: settings.allowanceDefaultMode,
          items: AllowanceMode.values,
          labelOf: (v) => v == AllowanceMode.paycheck ? 'Paycheck' : 'Goal',
          onChanged: (v) => saveSettingsField(repo, allowanceDefaultMode: v),
        ),
        _ChoiceTile<int>(
          icon: Icons.date_range_outlined,
          title: 'Spending baseline',
          value: settings.spendingBaselineDays,
          items: const [30, 60, 90],
          labelOf: (v) => '$v days',
          onChanged: (v) => saveSettingsField(repo, spendingBaselineDays: v),
        ),
        _ChoiceTile<RolloverResetType>(
          icon: Icons.replay_outlined,
          title: 'Cycle reset',
          value: settings.rolloverResetType,
          items: RolloverResetType.values,
          labelOf: (v) =>
              v == RolloverResetType.monthly ? 'Monthly' : 'Payday-based',
          onChanged: (v) => saveSettingsField(repo, rolloverResetType: v),
        ),
        _ChoiceTile<PaydayBehavior>(
          icon: Icons.payments_outlined,
          title: 'Default payday behavior',
          value: settings.defaultPaydayBehavior,
          items: PaydayBehavior.values,
          labelOf: (v) => v == PaydayBehavior.confirmActualOnPayday
              ? 'Confirm actual'
              : 'Auto-post expected',
          onChanged: (v) =>
              saveSettingsField(repo, defaultPaydayBehavior: v),
        ),

        _SectionHeader('Notifications'),
        _ToggleTile(
          icon: Icons.payments_outlined,
          title: 'Payday reminders',
          value: settings.paydayEnabled,
          onChanged: (v) => saveSettingsField(repo, paydayEnabled: v),
        ),
        _ToggleTile(
          icon: Icons.receipt_long_outlined,
          title: 'Bill due reminders',
          value: settings.billsEnabled,
          onChanged: (v) => saveSettingsField(repo, billsEnabled: v),
        ),
        _ToggleTile(
          icon: Icons.warning_amber_outlined,
          title: 'Overspend alerts',
          value: settings.overspendEnabled,
          onChanged: (v) => saveSettingsField(repo, overspendEnabled: v),
        ),
        _ToggleTile(
          icon: Icons.loop_outlined,
          title: 'Cycle reset info',
          value: settings.cycleResetEnabled,
          onChanged: (v) => saveSettingsField(repo, cycleResetEnabled: v),
        ),
        _ToggleTile(
          icon: Icons.nightlight_outlined,
          title: 'Nightly closeout',
          value: settings.nightlyCloseoutEnabled,
          onChanged: (v) =>
              saveSettingsField(repo, nightlyCloseoutEnabled: v),
        ),
        _SectionHeader('Debug'),
        _SchedulerStatusTile(),
        ListTile(
          leading: Icon(Icons.widgets_outlined, color: SaplingColors.support),
          title: const Text('Widget snapshot preview'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const WidgetPreviewScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SchedulerStatusTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRunAsync = ref.watch(schedulerLastRunAtProvider);
    return lastRunAsync.when(
      data: (at) => _InfoTile(
        icon: Icons.schedule_outlined,
        title: 'Scheduler last run',
        value: at ?? 'Never',
      ),
      loading: () => const ListTile(
        leading: Icon(Icons.schedule_outlined),
        title: Text('Scheduler last run'),
        trailing: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => _InfoTile(
        icon: Icons.schedule_outlined,
        title: 'Scheduler last run',
        value: '—',
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: SaplingColors.textSecondary,
                fontWeight: FontWeight.bold,
              )),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: SaplingColors.support),
      title: Text(title),
      trailing: Text(value,
          style: const TextStyle(
              color: SaplingColors.textSecondary, fontWeight: FontWeight.w600)),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: SaplingColors.support),
      title: Text(title),
      value: value,
      activeColor: SaplingColors.secondary,
      onChanged: onChanged,
    );
  }
}

class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: SaplingColors.support),
      title: Text(title),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        items: items
            .map((v) => DropdownMenuItem(value: v, child: Text(labelOf(v))))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
