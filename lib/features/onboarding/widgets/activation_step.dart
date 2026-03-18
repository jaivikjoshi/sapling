import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/leko_colors.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

class ActivationStep extends ConsumerWidget {
  const ActivationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final isSubmitting = state.isSubmitting;

    return StepScaffold(
      step: OnboardingStep.activation,
      title: 'Your plan is ready.',
      subtitle: 'We\'ve mapped your balance, protected your bills, and set your baseline. Léko is ready to help you breathe easier.',
      nextLabel: 'Enter my dashboard',
      isLoading: isSubmitting,
      onNext: () async {
        final success = await ref.read(onboardingControllerProvider.notifier).complete();
        if (success && context.mounted) {
          context.go('/home');
        }
      },
      onBack: () => ref.read(onboardingControllerProvider.notifier).back(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: LekoColors.onboardingSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: LekoColors.onboardingFill.withOpacity(0.3), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: LekoColors.onboardingFill.withOpacity(0.1),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 48,
                    color: LekoColors.onboardingFill,
                  ),
                  const SizedBox(height: 24),
                  _buildSummaryRow('Starting Balance', '\$${state.startingBalance.toStringAsFixed(0)}'),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Protected Bills', '${state.selectedBills.length} items'),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Primary Focus', state.focusGoal ?? 'General Wellness'),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Support Style', state.supportStyle?.name.toUpperCase() ?? 'STEADY'),
                ],
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 24),
              Text(
                state.error!,
                style: const TextStyle(color: LekoColors.error, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: LekoColors.onboardingTextSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: LekoColors.onboardingTextPrimary,
          ),
        ),
      ],
    );
  }
}
