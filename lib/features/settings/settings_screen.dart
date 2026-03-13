import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/settings_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Warm off-white
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Color(0xFF222529), fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: true,
      ),
      body: settingsAsync.when(
        data: (settings) => _SettingsBody(settings: settings, user: user),
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4A9D9C))),
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

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (isSignedIn) ...[
                _buildProfileCard(context, user!, repo),
                const SizedBox(height: 24),
              ],
              _buildSectionTitle('Budgeting'),
              _buildBudgetingCard(context, repo),
              const SizedBox(height: 24),
              _buildSectionTitle('Notifications'),
              _buildNotificationsCard(context, repo),
              const SizedBox(height: 24),
              _buildSectionTitle('App'),
              _buildAppCard(context, ref, isSignedIn),
              const SizedBox(height: 120), // Bottom padding to prevent clipping behind navigation bar
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF868E96),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, User user, dynamic repo) {
    final name = _displayName(user);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF4A9D9C).withOpacity(0.15),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFF4A9D9C),
                      fontSize: 24,
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
                        name.isEmpty ? 'Sapling User' : name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF222529)),
                      ),
                      const SizedBox(height: 2),
                      if (user.email != null)
                        Text(
                          user.email!,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF868E96)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.shade100),
          _SelectionRow<Currency>(
            icon: Icons.attach_money_rounded,
            title: 'Preferred currency',
            value: settings.baseCurrency,
            items: Currency.values,
            labelOf: (v) => v.name.toUpperCase(),
            onChanged: (v) => saveSettingsField(repo, baseCurrency: v),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetingCard(BuildContext context, dynamic repo) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _SelectionRow<AllowanceMode>(
            icon: Icons.calculate_rounded,
            title: 'Default allowance mode',
            value: settings.allowanceDefaultMode,
            items: AllowanceMode.values,
            labelOf: (v) => v == AllowanceMode.paycheck ? 'Paycheck' : 'Goal',
            onChanged: (v) => saveSettingsField(repo, allowanceDefaultMode: v),
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),
          _SelectionRow<int>(
            icon: Icons.date_range_rounded,
            title: 'Spending baseline',
            value: settings.spendingBaselineDays,
            items: const [30, 60, 90],
            labelOf: (v) => '$v days',
            onChanged: (v) => saveSettingsField(repo, spendingBaselineDays: v),
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),
          _SelectionRow<RolloverResetType>(
            icon: Icons.replay_rounded,
            title: 'Cycle reset',
            value: settings.rolloverResetType,
            items: RolloverResetType.values,
            labelOf: (v) => v == RolloverResetType.monthly ? 'Monthly' : 'Payday-based',
            onChanged: (v) => saveSettingsField(repo, rolloverResetType: v),
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),
          _SelectionRow<PaydayBehavior>(
            icon: Icons.payments_rounded,
            title: 'Default payday behavior',
            value: settings.defaultPaydayBehavior,
            items: PaydayBehavior.values,
            labelOf: (v) => v == PaydayBehavior.confirmActualOnPayday ? 'Confirm actual' : 'Auto-post expected',
            onChanged: (v) => saveSettingsField(repo, defaultPaydayBehavior: v),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard(BuildContext context, dynamic repo) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.payments_rounded,
            title: 'Payday reminders',
            value: settings.paydayEnabled,
            onChanged: (v) => saveSettingsField(repo, paydayEnabled: v),
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),
          _ToggleRow(
            icon: Icons.receipt_long_rounded,
            title: 'Bill due reminders',
            value: settings.billsEnabled,
            onChanged: (v) => saveSettingsField(repo, billsEnabled: v),
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),
          _ToggleRow(
            icon: Icons.warning_amber_rounded,
            title: 'Overspend alerts',
            iconColor: const Color(0xFFD96C6C), // Muted Coral
            value: settings.overspendEnabled,
            onChanged: (v) => saveSettingsField(repo, overspendEnabled: v),
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),
          _ToggleRow(
            icon: Icons.nightlight_round,
            title: 'Nightly closeout',
            value: settings.nightlyCloseoutEnabled,
            onChanged: (v) => saveSettingsField(repo, nightlyCloseoutEnabled: v),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(BuildContext context, WidgetRef ref, bool isSignedIn) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            onTap: () {},
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),
          _ActionRow(
            icon: Icons.info_outline_rounded,
            title: 'About Sapling',
            onTap: () {},
          ),
          Divider(height: 1, indent: 64, color: Colors.grey.shade100),
          _ActionRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
            isLast: !isSignedIn,
          ),
          if (isSignedIn) ...[
            Divider(height: 1, indent: 64, color: Colors.grey.shade100),
            _ActionRow(
              icon: Icons.logout_rounded,
              title: 'Sign out',
              titleColor: const Color(0xFFD96C6C),
              iconColor: const Color(0xFFD96C6C),
              showChevron: false,
              isLast: true,
              onTap: () => _logoutFromAll(context, ref),
            ),
          ]
        ],
      ),
    );
  }

  String _displayName(User user) {
    final meta = user.userMetadata;
    if (meta == null) return '';
    final name = meta['full_name'] ?? meta['name'];
    if (name is String) return name;
    return '';
  }

  Future<void> _logoutFromAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access your budget.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF868E96))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD96C6C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? iconColor;
  final bool isLast;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.iconColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(24)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? const Color(0xFF868E96), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Color(0xFF222529), fontWeight: FontWeight.w500),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: const Color(0xFF4A9D9C),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SelectionRow<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final bool isLast;

  const _SelectionRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.isLast = false,
  });

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 24),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF222529))),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = item == value;
                      return ListTile(
                        onTap: () {
                          onChanged(item);
                          Navigator.pop(context);
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        title: Text(
                          labelOf(item),
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF4A9D9C) : const Color(0xFF222529),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF4A9D9C)) : null,
                        tileColor: isSelected ? const Color(0xFF4A9D9C).withOpacity(0.05) : null,
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPicker(context),
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(24)) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF868E96), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF222529), fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                labelOf(value),
                style: const TextStyle(fontSize: 15, color: Color(0xFF868E96)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF868E96), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;
  final bool showChevron;
  final bool isLast;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.iconColor,
    this.showChevron = true,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(24)) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? const Color(0xFF868E96), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, color: titleColor ?? const Color(0xFF222529), fontWeight: FontWeight.w500),
                ),
              ),
              if (showChevron) const Icon(Icons.chevron_right_rounded, color: Color(0xFF868E96), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
