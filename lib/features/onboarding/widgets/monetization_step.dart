import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/leko_colors.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

class MonetizationStep extends ConsumerStatefulWidget {
  const MonetizationStep({super.key});

  @override
  ConsumerState<MonetizationStep> createState() => _MonetizationStepState();
}

class _MonetizationStepState extends ConsumerState<MonetizationStep> {
  bool _isAnnual = true;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      step: OnboardingStep.monetization,
      title: 'Try Léko Premium, free for 14 days.',
      subtitle: 'See exactly what you can safely spend today, stay ahead of bills, and build your safety net. Cancel anytime.',
      nextLabel: 'Start my 14-day free trial',
      secondaryLabel: 'Not right now',
      onNext: () {
        ref.read(onboardingControllerProvider.notifier).setOptedIntoTrial(true);
        ref.read(onboardingControllerProvider.notifier).next();
      },
      onSecondary: () {
        ref.read(onboardingControllerProvider.notifier).setOptedIntoTrial(false);
        ref.read(onboardingControllerProvider.notifier).next();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPricingOption(
            title: 'Annual Plan',
            price: '\$59.99',
            suffix: '/year',
            badge: 'Best Value - \$4.99/mo',
            isSelected: _isAnnual,
            onTap: () => setState(() => _isAnnual = true),
          ),
          const SizedBox(height: 16),
          _buildPricingOption(
            title: 'Monthly Plan',
            price: '\$5.99',
            suffix: '/month',
            isSelected: !_isAnnual,
            onTap: () => setState(() => _isAnnual = false),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingOption({
    required String title,
    required String price,
    required String suffix,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? LekoColors.onboardingFill.withOpacity(0.15) : LekoColors.onboardingSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? LekoColors.onboardingFill : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? LekoColors.onboardingFill : LekoColors.onboardingTextSecondary.withOpacity(0.5),
                  width: 2,
                ),
                color: isSelected ? LekoColors.onboardingFill : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: LekoColors.onboardingBackground)
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? LekoColors.onboardingTextPrimary : LekoColors.onboardingTextPrimary.withOpacity(0.9),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: LekoColors.onboardingFill.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: LekoColors.onboardingFill,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? LekoColors.onboardingTextPrimary : LekoColors.onboardingTextSecondary,
                        ),
                      ),
                      Text(
                        suffix,
                        style: TextStyle(
                          fontSize: 14,
                          color: LekoColors.onboardingTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
