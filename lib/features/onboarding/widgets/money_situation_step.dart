import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding_controller.dart';
import 'step_scaffold.dart';
import 'single_select_card.dart';

class MoneySituationStep extends ConsumerWidget {
  const MoneySituationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingControllerProvider.select((s) => s.moneySituation));
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.moneySituation,
      title: 'What feels most true about your money right now?',
      canProceed: selected != null,
      onNext: () => controller.next(),
      onBack: () => controller.back(),
      child: ListView(
        children: [
          SingleSelectCard(
            title: 'I make enough, but it disappears',
            isSelected: selected == 'disappears',
            onTap: () => controller.setMoneySituation('disappears'),
          ),
          SingleSelectCard(
            title: 'Bills sneak up on me',
            isSelected: selected == 'bills_sneak',
            onTap: () => controller.setMoneySituation('bills_sneak'),
          ),
          SingleSelectCard(
            title: 'I want to save, but it never sticks',
            isSelected: selected == 'save_struggle',
            onTap: () => controller.setMoneySituation('save_struggle'),
          ),
          SingleSelectCard(
            title: 'My income changes month to month',
            isSelected: selected == 'variable_income',
            onTap: () => controller.setMoneySituation('variable_income'),
          ),
          SingleSelectCard(
            title: 'I avoid checking my finances',
            isSelected: selected == 'avoidant',
            onTap: () => controller.setMoneySituation('avoidant'),
          ),
          SingleSelectCard(
            title: 'I\'m already organized and want better tools',
            isSelected: selected == 'organized',
            onTap: () => controller.setMoneySituation('organized'),
          ),
        ],
      ),
    );
  }
}
