import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding_controller.dart';
import 'step_scaffold.dart';
import 'single_select_card.dart';

class PrimaryNeedStep extends ConsumerWidget {
  const PrimaryNeedStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedNeed = ref.watch(onboardingControllerProvider.select((s) => s.primaryNeed));
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.primaryNeed,
      title: 'What brings you to Léko?',
      subtitle: 'We\'ll personalize your experience based on what matters most right now.',
      canProceed: selectedNeed != null,
      onNext: () => controller.next(),
      onBack: () => controller.back(),
      child: ListView(
        children: [
          SingleSelectCard(
            title: 'Protect my bills',
            description: 'Stop stressing about what\'s due and when.',
            icon: Icons.shield_rounded,
            isSelected: selectedNeed == 'bills',
            onTap: () => controller.setPrimaryNeed('bills'),
          ),
          SingleSelectCard(
            title: 'Know my safe to spend',
            description: 'Understand exactly how much I can guilt-free spend today.',
            icon: Icons.account_balance_wallet_rounded,
            isSelected: selectedNeed == 'spend',
            onTap: () => controller.setPrimaryNeed('spend'),
          ),
          SingleSelectCard(
            title: 'Grow my savings',
            description: 'Build a safety net and reach financial goals faster.',
            icon: Icons.trending_up_rounded,
            isSelected: selectedNeed == 'save',
            onTap: () => controller.setPrimaryNeed('save'),
          ),
          SingleSelectCard(
            title: 'Gain overall clarity',
            description: 'Just want a clearer picture of where my money is going.',
            icon: Icons.visibility_rounded,
            isSelected: selectedNeed == 'clarity',
            onTap: () => controller.setPrimaryNeed('clarity'),
          ),
        ],
      ),
    );
  }
}
