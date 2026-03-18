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
      title: 'Stay connected',
      subtitle: 'To provide the coaching style you just selected, Léko needs permission to send you timely updates.',
      nextLabel: 'Enable Notifications',
      secondaryLabel: 'Maybe later',
      onNext: () {
        // Here we would use permission_handler to actually request notifications
        // For now we just record they tapped it and move on
        ref.read(onboardingControllerProvider.notifier).setHasRequestedNotifications();
        ref.read(onboardingControllerProvider.notifier).next();
      },
      onSecondary: () {
        ref.read(onboardingControllerProvider.notifier).next();
      },
      onBack: () => ref.read(onboardingControllerProvider.notifier).back(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: LekoColors.onboardingSurface,
                shape: BoxShape.circle,
                border: Border.all(color: LekoColors.onboardingFill.withOpacity(0.3), width: 2),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                size: 64,
                color: LekoColors.onboardingFill,
              ),
            ),
            const SizedBox(height: 48),
            _buildBenefitRow(Icons.check_circle_outline, 'Get notified when it\'s safe to spend'),
            const SizedBox(height: 16),
            _buildBenefitRow(Icons.check_circle_outline, 'Receive timely bill reminders'),
            const SizedBox(height: 16),
            _buildBenefitRow(Icons.check_circle_outline, 'See your progress toward goals'),
            const SizedBox(height: 48),
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
