import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/leko_colors.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

class PermissionsStep extends ConsumerWidget {
  const PermissionsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StepScaffold(
      step: OnboardingStep.permissions,
      title: 'Stay ahead of bills, goals, and spending.',
      subtitle: 'Léko can remind you before bills hit, keep you aware of your daily spending pace, and help you maintain your streaks.',
      nextLabel: 'Enable notifications',
      secondaryLabel: 'Not now',
      onNext: () {
        ref.read(onboardingControllerProvider.notifier).setHasRequestedNotifications();
        ref.read(onboardingControllerProvider.notifier).next();
      },
      onSecondary: () {
        ref.read(onboardingControllerProvider.notifier).next();
      },
      onBack: () => ref.read(onboardingControllerProvider.notifier).back(),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: LekoColors.onboardingSurface,
                shape: BoxShape.circle,
                border: Border.all(color: LekoColors.onboardingFill.withOpacity(0.3), width: 2),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                size: 48,
                color: LekoColors.onboardingFill,
              ),
            ),
            const SizedBox(height: 32),
            _buildBenefitRow(Icons.check_circle_outline, 'Know what you can safely spend each day'),
            const SizedBox(height: 16),
            _buildBenefitRow(Icons.check_circle_outline, 'Get a heads-up before bills arrive'),
            const SizedBox(height: 16),
            _buildBenefitRow(Icons.check_circle_outline, 'Track your streaks and progress'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: LekoColors.onboardingFill, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: LekoColors.onboardingTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
