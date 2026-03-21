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
      title: 'Your money plan is ready.',
      subtitle: 'You now have a clearer starting point — and Léko will keep helping you improve from here.',
      nextLabel: 'See my plan',
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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: LekoColors.onboardingSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: LekoColors.onboardingFill.withOpacity(0.2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: LekoColors.onboardingFill.withOpacity(0.08),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Safe-to-spend highlight
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: LekoColors.onboardingFill.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Safe to spend today',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: LekoColors.onboardingFill.withOpacity(0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${_estimateSafeToSpend(state)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: LekoColors.onboardingFill,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSummaryRow(
                    Icons.account_balance_wallet_rounded,
                    'Starting balance',
                    '\$${state.startingBalance.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    Icons.shield_rounded,
                    'Protected bills',
                    '${state.selectedBills.length} item${state.selectedBills.length == 1 ? '' : 's'}',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    Icons.eco_rounded,
                    'First goal',
                    state.focusGoal ?? 'None yet',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    Icons.notifications_rounded,
                    'Support style',
                    _supportStyleLabel(state.supportStyle),
                  ),
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

  String _estimateSafeToSpend(OnboardingState state) {
    // Rough estimate: balance minus bill reserves (100 per bill placeholder) divided by 30 days
    final billReserves = state.selectedBills.length * 100.0;
    final remaining = (state.startingBalance - billReserves).clamp(0, double.infinity);
    final daily = (remaining / 30).round();
    return daily.toString();
  }

  String _supportStyleLabel(SupportStyle? style) {
    return switch (style) {
      SupportStyle.gentleReminders => 'Gentle',
      SupportStyle.dailyLimits => 'Daily limits',
      SupportStyle.goalMotivation => 'Goal-focused',
      SupportStyle.billAlerts => 'Bill alerts',
      SupportStyle.weeklyCheckins => 'Weekly',
      null => 'Balanced',
    };
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: LekoColors.onboardingTextSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: LekoColors.onboardingTextSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: LekoColors.onboardingTextPrimary,
          ),
        ),
      ],
    );
  }
}
