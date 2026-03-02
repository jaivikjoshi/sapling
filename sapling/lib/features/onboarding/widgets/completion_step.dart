import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/sapling_colors.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

class CompletionStep extends ConsumerWidget {
  const CompletionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.completion,
      title: 'You\'re all set!',
      subtitle: 'Here\'s a summary of your setup.',
      nextLabel: 'Get Started',
      isLoading: state.isSubmitting,
      onNext: () async {
        final success = await ctrl.complete();
        if (success && context.mounted) context.go('/home');
      },
      onBack: () => ctrl.back(),
      child: ListView(
        children: [
          _SummaryRow(
            label: 'Currency',
            value: state.currency.name.toUpperCase(),
          ),
          _SummaryRow(
            label: 'Starting balance',
            value: '\$${state.startingBalance.toStringAsFixed(2)}',
          ),
          _SummaryRow(
            label: 'Income schedules',
            value: state.incomes.isEmpty
                ? 'None (add later)'
                : state.incomes.map((i) => i.name).join(', '),
          ),
          _SummaryRow(
            label: 'Cycle reset',
            value: state.rolloverType.name == 'monthly'
                ? 'Monthly'
                : 'Payday-based',
          ),
          _SummaryRow(
            label: 'Baseline window',
            value: '${state.baselineDays} days',
          ),
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: TextStyle(color: SaplingColors.error, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SaplingColors.textSecondary,
                    )),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
          ),
        ],
      ),
    );
  }
}
