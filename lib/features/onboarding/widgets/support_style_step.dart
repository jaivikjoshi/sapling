import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding_controller.dart';
import 'step_scaffold.dart';
import 'single_select_card.dart';

class SupportStyleStep extends ConsumerWidget {
  const SupportStyleStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStyle = ref.watch(onboardingControllerProvider.select((s) => s.supportStyle));
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.supportStyle,
      title: 'How should Léko help you stay on track?',
      canProceed: selectedStyle != null,
      onNext: () => controller.next(),
      onBack: () => controller.back(),
      child: ListView(
        children: [
          SingleSelectCard(
            title: 'Gentle reminders',
            description: 'Minimal alerts — just the essentials.',
            isSelected: selectedStyle == SupportStyle.gentleReminders,
            onTap: () => controller.setSupportStyle(SupportStyle.gentleReminders),
          ),
          SingleSelectCard(
            title: 'Clear daily limits',
            description: 'Show me exactly what I can spend each day.',
            isSelected: selectedStyle == SupportStyle.dailyLimits,
            onTap: () => controller.setSupportStyle(SupportStyle.dailyLimits),
          ),
          SingleSelectCard(
            title: 'Goal-focused motivation',
            description: 'Keep me focused on progress toward my goals.',
            isSelected: selectedStyle == SupportStyle.goalMotivation,
            onTap: () => controller.setSupportStyle(SupportStyle.goalMotivation),
          ),
          SingleSelectCard(
            title: 'Bill alerts',
            description: 'Make sure I never miss a payment.',
            isSelected: selectedStyle == SupportStyle.billAlerts,
            onTap: () => controller.setSupportStyle(SupportStyle.billAlerts),
          ),
          SingleSelectCard(
            title: 'Weekly money check-ins',
            description: 'A calm weekly summary instead of daily pings.',
            isSelected: selectedStyle == SupportStyle.weeklyCheckins,
            onTap: () => controller.setSupportStyle(SupportStyle.weeklyCheckins),
          ),
        ],
      ),
    );
  }
}
