import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sapling_colors.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

class NotificationsStep extends ConsumerWidget {
  const NotificationsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    final state = ref.watch(onboardingControllerProvider);

    return StepScaffold(
      step: OnboardingStep.notifications,
      title: 'Notifications',
      subtitle: 'Choose which reminders you\'d like. You can change these later in Settings.',
      onNext: () => ctrl.next(),
      onBack: () => ctrl.back(),
      child: ListView(
        children: [
          _NotifTile(
            icon: Icons.payments_outlined,
            title: 'Payday reminders',
            subtitle: 'Get notified when pay is due',
            value: state.paydayNotifs,
            onChanged: (v) => ctrl.setNotifs(payday: v),
          ),
          _NotifTile(
            icon: Icons.receipt_long_outlined,
            title: 'Bill due reminders',
            subtitle: 'Heads-up before bills are due',
            value: state.billNotifs,
            onChanged: (v) => ctrl.setNotifs(bill: v),
          ),
          _NotifTile(
            icon: Icons.warning_amber_outlined,
            title: 'Overspend alerts',
            subtitle: 'Know when you exceed your allowance',
            value: state.overspendNotifs,
            onChanged: (v) => ctrl.setNotifs(overspend: v),
          ),
          _NotifTile(
            icon: Icons.nightlight_outlined,
            title: 'Nightly closeout',
            subtitle: '1-minute check-in each evening',
            value: state.closeoutNotifs,
            onChanged: (v) => ctrl.setNotifs(closeout: v),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icon, color: SaplingColors.support),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        value: value,
        activeColor: SaplingColors.secondary,
        onChanged: onChanged,
      ),
    );
  }
}
