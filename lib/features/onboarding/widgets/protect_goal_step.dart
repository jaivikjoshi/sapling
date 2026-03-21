import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding_controller.dart';
import 'step_scaffold.dart';
import 'single_select_card.dart';

class ProtectGoalStep extends ConsumerWidget {
  const ProtectGoalStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingControllerProvider.select((s) => s.protectGoal));
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.protectGoal,
      title: 'What matters most right now?',
      canProceed: selected != null,
      onNext: () => controller.next(),
      onBack: () => controller.back(),
      child: ListView(
        children: [
          SingleSelectCard(
            title: 'Paying bills on time',
            isSelected: selected == 'bills_on_time',
            onTap: () => controller.setProtectGoal('bills_on_time'),
          ),
          SingleSelectCard(
            title: 'Building an emergency buffer',
            isSelected: selected == 'emergency_buffer',
            onTap: () => controller.setProtectGoal('emergency_buffer'),
          ),
          SingleSelectCard(
            title: 'Saving for something specific',
            isSelected: selected == 'specific_saving',
            onTap: () => controller.setProtectGoal('specific_saving'),
          ),
          SingleSelectCard(
            title: 'Spending less day to day',
            isSelected: selected == 'spend_less',
            onTap: () => controller.setProtectGoal('spend_less'),
          ),
          SingleSelectCard(
            title: 'Feeling less stressed about money',
            isSelected: selected == 'less_stress',
            onTap: () => controller.setProtectGoal('less_stress'),
          ),
        ],
      ),
    );
  }
}
