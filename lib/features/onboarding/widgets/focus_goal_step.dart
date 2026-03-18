import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding_controller.dart';
import 'step_scaffold.dart';
import 'single_select_card.dart';

class FocusGoalStep extends ConsumerWidget {
  const FocusGoalStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGoal = ref.watch(onboardingControllerProvider.select((s) => s.focusGoal));
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.focusGoal,
      title: 'What\'s the primary target?',
      subtitle: 'Pick one focus area to start. Setting aside even \$10/month builds momentum.',
      canProceed: selectedGoal != null,
      onNext: () => controller.next(),
      onBack: () => controller.back(),
      child: ListView(
        children: [
          SingleSelectCard(
            title: 'Emergency Fund',
            description: 'A safety net for the unexpected.',
            icon: Icons.health_and_safety_rounded,
            isSelected: selectedGoal == 'Emergency Fund',
            onTap: () => controller.setFocusGoal('Emergency Fund'),
          ),
          SingleSelectCard(
            title: 'Travel & Vacations',
            description: 'Save up for your next big trip.',
            icon: Icons.flight_takeoff_rounded,
            isSelected: selectedGoal == 'Travel & Vacations',
            onTap: () => controller.setFocusGoal('Travel & Vacations'),
          ),
          SingleSelectCard(
            title: 'Large Purchase',
            description: 'A new laptop, furniture, or home upgrade.',
            icon: Icons.shopping_bag_rounded,
            isSelected: selectedGoal == 'Large Purchase',
            onTap: () => controller.setFocusGoal('Large Purchase'),
          ),
          SingleSelectCard(
            title: 'Debt Payoff',
            description: 'Crush those high-interest balances.',
            icon: Icons.money_off_csred_rounded,
            isSelected: selectedGoal == 'Debt Payoff',
            onTap: () => controller.setFocusGoal('Debt Payoff'),
          ),
        ],
      ),
    );
  }
}
