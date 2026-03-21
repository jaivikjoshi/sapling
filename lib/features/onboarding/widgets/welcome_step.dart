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
      title: 'Grow your money with more clarity.',
      subtitle: 'Léko helps you track spending, plan ahead, and know what you can safely spend — without falling behind on bills or goals.',
      nextLabel: 'Continue',
      onNext: () => ref.read(onboardingControllerProvider.notifier).next(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
