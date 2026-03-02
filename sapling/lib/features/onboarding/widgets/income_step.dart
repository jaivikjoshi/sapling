import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sapling_colors.dart';
import '../../../domain/models/enums.dart';
import '../onboarding_controller.dart';
import 'income_form_sheet.dart';
import 'step_scaffold.dart';

class IncomeStep extends ConsumerWidget {
  const IncomeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    final incomes = ref.watch(
      onboardingControllerProvider.select((s) => s.incomes),
    );

    return StepScaffold(
      step: OnboardingStep.income,
      title: 'Recurring income',
      subtitle: 'Add your pay schedules. You can skip and add later.',
      nextLabel: incomes.isEmpty ? 'Skip' : 'Continue',
      onNext: () => ctrl.next(),
      onBack: () => ctrl.back(),
      child: Column(
        children: [
          ...incomes.map((inc) => _IncomeTile(
                income: inc,
                onRemove: () => ctrl.removeIncome(inc.tempId),
              )),
          if (incomes.isNotEmpty) const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showAddSheet(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add income schedule'),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => IncomeFormSheet(
        onSave: (data) {
          ref.read(onboardingControllerProvider.notifier).addIncome(data);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  const _IncomeTile({required this.income, required this.onRemove});

  final OnboardingIncomeData income;
  final VoidCallback onRemove;

  String get _freqLabel => switch (income.frequency) {
        IncomeFrequency.weekly => 'Weekly',
        IncomeFrequency.biweekly => 'Bi-weekly',
        IncomeFrequency.monthly => 'Monthly',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(income.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$_freqLabel • ${income.expectedAmount != null ? "\$${income.expectedAmount!.toStringAsFixed(2)}" : "Amount TBD"}'),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: SaplingColors.labelRed),
          onPressed: onRemove,
        ),
      ),
    );
  }
}
