import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/sapling_colors.dart';
import '../../../domain/models/enums.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

class RolloverStep extends ConsumerWidget {
  const RolloverStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    final state = ref.watch(onboardingControllerProvider);
    final incomes = state.incomes;
    final needsAnchor = state.rolloverType == RolloverResetType.paydayBased;
    final canProceed = !needsAnchor ||
        (incomes.isNotEmpty && state.paydayAnchorTempId != null);

    return StepScaffold(
      step: OnboardingStep.rollover,
      title: 'Allowance reset cycle',
      subtitle: 'When should your unspent allowance reset to zero?',
      canProceed: canProceed,
      onNext: () => ctrl.next(),
      onBack: () => ctrl.back(),
      child: ListView(
        children: [
          _OptionTile(
            title: 'Monthly',
            subtitle: 'Resets on the 1st of each month',
            isSelected: state.rolloverType == RolloverResetType.monthly,
            onTap: () => ctrl.setRolloverType(RolloverResetType.monthly),
          ),
          const SizedBox(height: 12),
          _OptionTile(
            title: 'Payday-based',
            subtitle: 'Resets each payday cycle (requires an anchor income)',
            isSelected: state.rolloverType == RolloverResetType.paydayBased,
            onTap: () =>
                ctrl.setRolloverType(RolloverResetType.paydayBased),
          ),
          if (needsAnchor) ...[
            const SizedBox(height: 24),
            Text('Select Payday Anchor',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            if (incomes.isEmpty)
              Text(
                'Go back and add a recurring income first.',
                style: TextStyle(color: SaplingColors.error, fontSize: 13),
              )
            else
              ...incomes.map((inc) => RadioListTile<String>(
                    title: Text(inc.name),
                    value: inc.tempId,
                    groupValue: state.paydayAnchorTempId,
                    activeColor: SaplingColors.secondary,
                    onChanged: (v) => ctrl.setPaydayAnchor(v),
                  )),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? SaplingColors.secondary : SaplingColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: SaplingColors.textSecondary,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
