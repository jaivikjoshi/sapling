import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/auth_providers.dart';
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
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) => _SettingsBody(settings: settings, user: user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings, this.user});

  final UserSettings settings;
  final User? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(settingsRepositoryProvider);
    final isSignedIn = user != null;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (isSignedIn) ...[
          _SectionHeader('Profile'),
          _ProfileHeader(user: user!),
          _ActionTile(
            icon: Icons.person_outline,
            title: 'Name',
            value: _displayName(user!),
            onTap: () => _showEditNameSheet(context, ref, user!),
          ),
          _InfoTile(
            icon: Icons.email_outlined,
            title: 'Email',
            value: user!.email ?? '—',
          ),
          _ActionTile(
            icon: Icons.photo_camera_outlined,
            title: 'Profile photo',
            value: 'Tap to change',
            onTap: () {
              // TODO: Implement profile photo upload
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile photo coming soon')),
              );
            },
          ),
          _ChoiceTile<Currency>(
            icon: Icons.attach_money,
            title: 'Preferred currency',
            value: settings.baseCurrency,
            items: Currency.values,
            labelOf: (v) => v.name.toUpperCase(),
            onChanged: (v) =>
                saveSettingsField(repo, baseCurrency: v),
          ),
          _ActionTile(
            icon: Icons.public_outlined,
            title: 'Country / region',
            value: 'Set in profile',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            },
          ),
          _InfoTile(
            icon: Icons.schedule_outlined,
            title: 'Time zone',
            value: DateTime.now().timeZoneName,
          ),
          _SectionHeader('Security'),
          _ActionTile(
            icon: Icons.lock_outline,
            title: 'Change password',
            value: '',
            onTap: () => _showChangePasswordSheet(context, ref),
          ),
          _InfoTile(
            icon: Icons.fingerprint,
            title: 'Biometric lock',
            value: 'Coming soon',
          ),
          _InfoTile(
            icon: Icons.pin_outlined,
            title: 'PIN lock',
            value: 'Coming soon',
          ),
          _InfoTile(
            icon: Icons.security_outlined,
            title: 'Two-factor authentication',
            value: 'Coming soon',
          ),
          _InfoTile(
            icon: Icons.devices_outlined,
            title: 'Trusted devices',
            value: 'Coming soon',
          ),
          _ActionTile(
            icon: Icons.logout,
            title: 'Logout from all devices',
            value: '',
            onTap: () => _logoutFromAll(context, ref),
          ),
          _SectionHeader('Data + accounts'),
          _ActionTile(
            icon: Icons.download_outlined,
            title: 'Export data as CSV',
            value: '',
            onTap: () => _exportData(context, ref),
          ),
          _ActionTile(
            icon: Icons.pause_circle_outlined,
            title: 'Deactivate account',
            value: '',
            onTap: () => _showDeactivateDialog(context, ref),
            destructive: true,
          ),
          _ActionTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete account',
            value: '',
            onTap: () => _showDeleteAccountDialog(context, ref),
            destructive: true,
          ),
        ],
        _SectionHeader('General'),
        if (!isSignedIn)
          _ChoiceTile<Currency>(
            icon: Icons.attach_money,
            title: 'Currency',
            value: settings.baseCurrency,
            items: Currency.values,
            labelOf: (v) => v.name.toUpperCase(),
            onChanged: (v) => saveSettingsField(repo, baseCurrency: v),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? SaplingColors.labelRed : SaplingColors.support;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: destructive
            ? TextStyle(color: SaplingColors.labelRed, fontWeight: FontWeight.w600)
            : null,
      ),
      trailing: value.isEmpty
          ? const Icon(Icons.chevron_right, color: SaplingColors.textSecondary)
          : Text(value,
              style: TextStyle(
                  color: SaplingColors.textSecondary, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(user);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: SaplingColors.secondary.withValues(alpha: 0.3),
            child: Text(
              initial,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: SaplingColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'No name' : name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: SaplingColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _displayName(User user) {
  final meta = user.userMetadata;
  if (meta == null) return '';
  final name = meta['full_name'] ?? meta['name'];
  if (name is String) return name;
  return '';
}

void _showEditNameSheet(BuildContext context, WidgetRef ref, User user) {
  // TODO: Implement edit name via Supabase auth updateUser
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Edit name coming soon')),
  );
}

Future<void> _showChangePasswordSheet(BuildContext context, WidgetRef ref) {
  final client = ref.read(supabaseClientProvider);
  final newPasswordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Change password', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordCtrl,
              decoration: const InputDecoration(
                labelText: 'New password',
                hintText: 'At least 6 characters',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                final newPass = newPasswordCtrl.text;
                final confirm = confirmCtrl.text;
                if (newPass.length < 6) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters')),
                  );
                  return;
                }
                if (newPass != confirm) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
                  );
                  return;
                }
                try {
                  await client.auth.updateUser(UserAttributes(password: newPass));
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Password updated')),
                    );
                  }
                } on AuthException catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
              child: const Text('Update password'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _logoutFromAll(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Logout from all devices?'),
      content: const Text(
        'You will need to sign in again on this device. Other sessions will also be signed out.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    await ref.read(supabaseClientProvider).auth.signOut();
    if (context.mounted) context.go('/login');
  }
}

void _exportData(BuildContext context, WidgetRef ref) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Export CSV coming soon')),
  );
}

void _showDeactivateDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Deactivate account?'),
      content: const Text(
        'Your data will be preserved but you will not be able to sign in until you reactivate. Contact support to reactivate.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SaplingColors.labelRed,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Deactivation requires support. Please contact us.')),
            );
          },
          child: const Text('Deactivate'),
        ),
      ],
    ),
  );
}

void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete account?'),
      content: const Text(
        'This will permanently delete your account and all your data. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SaplingColors.labelRed,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Account deletion requires contacting support. Your data will be removed within 30 days.',
                ),
              ),
            );
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
