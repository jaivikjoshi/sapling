import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding_controller.dart';
import 'step_scaffold.dart';
import 'single_select_card.dart';

class RhythmStep extends ConsumerWidget {
  const RhythmStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRhythm = ref.watch(onboardingControllerProvider.select((s) => s.rhythm));
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.rhythm,
      title: 'How does your income flow?',
      subtitle: 'This helps us sync your spending plan with reality.',
      canProceed: selectedRhythm != null,
      onNext: () => controller.next(),
      onBack: () => controller.back(),
      child: ListView(
        children: [
          SingleSelectCard(
            title: 'Predictable',
            description: 'I know exactly when and how much I get paid.',
            icon: Icons.calendar_today_rounded,
            isSelected: selectedRhythm == IncomeRhythm.predictable,
            onTap: () => controller.setRhythm(IncomeRhythm.predictable),
          ),
          SingleSelectCard(
            title: 'Irregular',
            description: 'My income fluctuates or the timing varies (freelance, gig, sales).',
            icon: Icons.waves_rounded,
            isSelected: selectedRhythm == IncomeRhythm.irregular,
            onTap: () => controller.setRhythm(IncomeRhythm.irregular),
          ),
        ],
      ),
    );
  }
}
