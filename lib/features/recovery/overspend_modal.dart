import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/recovery_providers.dart';
import '../../core/providers/widget_snapshot_providers.dart';
import '../../core/theme/leko_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/services/overspend_detector.dart';

class OverspendModal extends ConsumerWidget {
  const OverspendModal({
    super.key,
    required this.result,
    required this.triggerTransactionId,
  });

  final OverspendResult result;
  final String triggerTransactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: LekoColors.labelRed, size: 48),
          const SizedBox(height: 12),
          Text(
            'You overspent today',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: LekoColors.labelRed,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Over by ${formatCurrency(result.overspendAmount)}',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            'Spent ${formatCurrency(result.spendToday)} of '
            '${formatCurrency(result.allowanceToday)} allowance',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: LekoColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Choose a recovery plan',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _PlanOption(
            icon: Icons.calendar_view_week,
            title: 'Reduce next 7 days',
            subtitle:
                '-${formatCurrency(result.overspendAmount / 7)}/day for 7 days',
            onTap: () => _selectPlan(context, ref, 'reduce_7'),
          ),
          const SizedBox(height: 8),
          _PlanOption(
            icon: Icons.calendar_month,
            title: 'Reduce next 14 days',
            subtitle:
                '-${formatCurrency(result.overspendAmount / 14)}/day for 14 days',
            onTap: () => _selectPlan(context, ref, 'reduce_14'),
          ),
          const SizedBox(height: 8),
          _PlanOption(
            icon: Icons.weekend,
            title: 'Reduce weekends only',
            subtitle:
                '-${formatCurrency(result.overspendAmount / 4)}/day on next 4 weekend days',
            onTap: () => _selectPlan(context, ref, 'weekends'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPlan(
      BuildContext context, WidgetRef ref, String plan) async {
    final service = ref.read(recoveryPlanServiceProvider);

    switch (plan) {
      case 'reduce_7':
        await service.createReduceNextNDays(
          triggerTransactionId: triggerTransactionId,
          overspendAmount: result.overspendAmount,
          days: 7,
        );
      case 'reduce_14':
        await service.createReduceNextNDays(
          triggerTransactionId: triggerTransactionId,
          overspendAmount: result.overspendAmount,
          days: 14,
        );
      case 'weekends':
        await service.createReduceWeekendsOnly(
          triggerTransactionId: triggerTransactionId,
          overspendAmount: result.overspendAmount,
          weekendDays: 4,
        );
    }

    ref.read(snapshotWriterProvider).writeSnapshot();
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery plan activated.')),
      );
    }
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LekoColors.labelRed.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: LekoColors.labelRed, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: LekoColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: LekoColors.divider),
            ],
          ),
        ),
      ),
    );
  }
}
