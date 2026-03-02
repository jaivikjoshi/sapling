import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sapling_colors.dart';
import '../../../domain/models/enums.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

class CurrencyStep extends ConsumerWidget {
  const CurrencyStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final currency = ref.watch(
      onboardingControllerProvider.select((s) => s.currency),
    );

    return StepScaffold(
      step: OnboardingStep.currency,
      title: 'Choose your currency',
      subtitle: 'This will be used across the entire app.',
      onNext: () => controller.next(),
      child: Column(
        children: [
          _CurrencyOption(
            label: 'CAD — Canadian Dollar',
            symbol: 'CA\$',
            isSelected: currency == Currency.cad,
            onTap: () => controller.setCurrency(Currency.cad),
          ),
          const SizedBox(height: 12),
          _CurrencyOption(
            label: 'USD — US Dollar',
            symbol: 'US\$',
            isSelected: currency == Currency.usd,
            onTap: () => controller.setCurrency(Currency.usd),
          ),
        ],
      ),
    );
  }
}

class _CurrencyOption extends StatelessWidget {
  const _CurrencyOption({
    required this.label,
    required this.symbol,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String symbol;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? SaplingColors.secondary.withValues(alpha: 0.1)
          : SaplingColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? SaplingColors.secondary : SaplingColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(symbol, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? SaplingColors.secondary : SaplingColors.textSecondary,
              )),
              const SizedBox(width: 16),
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),
              if (isSelected) const Icon(Icons.check_circle, color: SaplingColors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
