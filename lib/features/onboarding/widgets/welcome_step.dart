import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/leko_colors.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StepScaffold(
      step: OnboardingStep.welcome,
      title: 'Welcome to Léko.',
      subtitle: 'Money without the stress. A system designed to give you clarity, protect your bills, and build your future.',
      nextLabel: 'Let\'s begin',
      onNext: () => ref.read(onboardingControllerProvider.notifier).next(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A placeholder for a beautiful premium graphic/logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    LekoColors.onboardingFill.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.eco_rounded,
                  size: 64,
                  color: LekoColors.onboardingFill,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
