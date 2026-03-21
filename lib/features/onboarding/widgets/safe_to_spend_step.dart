import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/leko_colors.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

class SafeToSpendStep extends ConsumerWidget {
  const SafeToSpendStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StepScaffold(
      step: OnboardingStep.safeToSpend,
      title: 'Know what you can safely spend today.',
      subtitle: 'Léko looks at your balance, upcoming bills, goals, and pay cycle to estimate what\'s safe — so you can spend with more confidence.',
      nextLabel: 'Continue',
      onNext: () => ref.read(onboardingControllerProvider.notifier).next(),
      onBack: () => ref.read(onboardingControllerProvider.notifier).back(),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: LekoColors.onboardingSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: LekoColors.onboardingFill.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMockupRow(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Your balance',
                value: '\$2,400',
                color: LekoColors.onboardingTextPrimary,
              ),
              const SizedBox(height: 4),
              _buildDivider(),
              const SizedBox(height: 4),
              _buildMockupRow(
                icon: Icons.receipt_long_rounded,
                label: 'Upcoming bills',
                value: '– \$1,200',
                color: LekoColors.onboardingTextSecondary,
              ),
              const SizedBox(height: 4),
              _buildDivider(),
              const SizedBox(height: 4),
              _buildMockupRow(
                icon: Icons.savings_rounded,
                label: 'Goal reserves',
                value: '– \$200',
                color: LekoColors.onboardingTextSecondary,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: LekoColors.onboardingFill.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: LekoColors.onboardingFill.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Safe to spend today',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: LekoColors.onboardingFill,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '\$62',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: LekoColors.onboardingFill,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildMockupRow(
                icon: Icons.eco_rounded,
                label: 'Goal progress',
                value: '40%',
                color: LekoColors.onboardingFill,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockupRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: LekoColors.onboardingTextSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: LekoColors.onboardingTextSecondary.withOpacity(0.15),
    );
  }
}
