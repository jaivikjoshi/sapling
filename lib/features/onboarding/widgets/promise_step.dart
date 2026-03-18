import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/leko_colors.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

class PromiseStep extends ConsumerWidget {
  const PromiseStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StepScaffold(
      step: OnboardingStep.promise,
      title: 'The Léko Promise',
      subtitle: '',
      nextLabel: 'I\'m ready',
      onNext: () => ref.read(onboardingControllerProvider.notifier).next(),
      onBack: () => ref.read(onboardingControllerProvider.notifier).back(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 48,
              color: LekoColors.onboardingFill,
            ),
            const SizedBox(height: 32),
            Text(
              'We don\'t care what you did yesterday.\nWe care what you do today.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: LekoColors.onboardingTextPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your past doesn\'t define your financial future. Let\'s build a system that works for you right now.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: LekoColors.onboardingTextSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
