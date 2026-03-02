import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sapling_colors.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

class BaselineStep extends ConsumerWidget {
  const BaselineStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    final days = ref.watch(
      onboardingControllerProvider.select((s) => s.baselineDays),
    );

    return StepScaffold(
      step: OnboardingStep.baseline,
      title: 'Spending baseline',
      subtitle:
          'How many days of spending history should we use to estimate your daily variable spend?',
      onNext: () => ctrl.next(),
      onBack: () => ctrl.back(),
      child: Column(
        children: [
          for (final d in [30, 60, 90])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DayOption(
                days: d,
                isSelected: days == d,
                onTap: () => ctrl.setBaselineDays(d),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'New users start with no history. Estimates will improve as you log expenses.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: SaplingColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DayOption extends StatelessWidget {
  const _DayOption({
    required this.days,
    required this.isSelected,
    required this.onTap,
  });

  final int days;
  final bool isSelected;
  final VoidCallback onTap;

  String get _label => switch (days) {
        30 => '30 days — Recent spending',
        60 => '60 days — Broader view',
        90 => '90 days — Most stable',
        _ => '$days days',
      };

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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? SaplingColors.secondary : SaplingColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(_label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        )),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: SaplingColors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
