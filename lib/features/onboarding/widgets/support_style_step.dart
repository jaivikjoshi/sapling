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
      title: 'How do you want us to coach you?',
      subtitle: 'We adjust our tone and intervention level based on your preference.',
      canProceed: selectedStyle != null,
      onNext: () => controller.next(),
      onBack: () => controller.back(),
      child: ListView(
        children: [
          SingleSelectCard(
            title: 'Gentle',
            description: 'Minimal alerts. Just show me the numbers and let me navigate.',
            icon: Icons.self_improvement_rounded,
            isSelected: selectedStyle == SupportStyle.gentle,
            onTap: () => controller.setSupportStyle(SupportStyle.gentle),
          ),
          SingleSelectCard(
            title: 'Steady',
            description: 'Balanced nudges when bills are due or when I get paid.',
            icon: Icons.water_rounded,
            isSelected: selectedStyle == SupportStyle.steady,
            onTap: () => controller.setSupportStyle(SupportStyle.steady),
          ),
          SingleSelectCard(
            title: 'Focused',
            description: 'Active accountability. Alert me if I stray from my spending baseline.',
            icon: Icons.track_changes_rounded,
            isSelected: selectedStyle == SupportStyle.focused,
            onTap: () => controller.setSupportStyle(SupportStyle.focused),
          ),
        ],
      ),
    );
  }
}
