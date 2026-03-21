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
      title: 'What do you want Léko to help with first?',
      subtitle: 'We\'ll tailor your setup so Léko feels useful from day one.',
      canProceed: selectedNeed != null,
      onNext: () => controller.next(),
      onBack: () => controller.back(),
      child: ListView(
        children: [
          SingleSelectCard(
            title: 'Stop overspending',
            isSelected: selectedNeed == 'overspending',
            onTap: () => controller.setPrimaryNeed('overspending'),
          ),
          SingleSelectCard(
            title: 'Stay on top of bills',
            isSelected: selectedNeed == 'bills',
            onTap: () => controller.setPrimaryNeed('bills'),
          ),
          SingleSelectCard(
            title: 'Save more consistently',
            isSelected: selectedNeed == 'save',
            onTap: () => controller.setPrimaryNeed('save'),
          ),
          SingleSelectCard(
            title: 'Understand where my money goes',
            isSelected: selectedNeed == 'clarity',
            onTap: () => controller.setPrimaryNeed('clarity'),
          ),
          SingleSelectCard(
            title: 'Build better money habits',
            isSelected: selectedNeed == 'habits',
            onTap: () => controller.setPrimaryNeed('habits'),
          ),
          SingleSelectCard(
            title: 'Plan around irregular income',
            isSelected: selectedNeed == 'irregular',
            onTap: () => controller.setPrimaryNeed('irregular'),
          ),
        ],
      ),
    );
  }
}
