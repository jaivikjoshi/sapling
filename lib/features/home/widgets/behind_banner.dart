import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/allowance_providers.dart';
import '../../../core/providers/recovery_providers.dart';
import '../../../core/theme/leko_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/db/leko_database.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/services/recovery_plan_service.dart';

class BehindBanner extends ConsumerWidget {
  const BehindBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(effectiveAllowanceModeProvider);
    final behind = mode == AllowanceMode.paycheck
        ? _paycheckBehind(ref)
        : _goalBehind(ref);
    final activePlan = ref.watch(activeRecoveryPlanProvider).valueOrNull;

    if ((behind == null || behind <= 0) && activePlan == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          if (behind != null && behind > 0) _buildBehindRow(context, behind),
          if (activePlan != null) ...[
            const SizedBox(height: 6),
            _ActivePlanChip(plan: activePlan, ref: ref),
          ],
        ],
      ),
    );
  }

  Widget _buildBehindRow(BuildContext context, double behind) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LekoColors.labelRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: LekoColors.labelRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: LekoColors.labelRed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Behind by ${formatCurrency(behind)}',
              style: const TextStyle(
                color: LekoColors.labelRed,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double? _paycheckBehind(WidgetRef ref) {
    final r = ref.watch(paycheckAllowanceProvider).valueOrNull;
    return r?.behindAmount;
  }

  double? _goalBehind(WidgetRef ref) {
    final r = ref.watch(goalAllowanceProvider).valueOrNull;
    return r?.behindAmount;
  }
}

class _ActivePlanChip extends StatelessWidget {
  const _ActivePlanChip({required this.plan, required this.ref});
  final RecoveryPlan plan;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final todayAdj = RecoveryPlanService.computeTodayAdjustment(plan);
    final label = _planLabel(plan.planType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: LekoColors.labelOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: LekoColors.labelOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.healing,
              color: LekoColors.labelOrange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recovery: $label',
                  style: const TextStyle(
                    color: LekoColors.labelOrange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (todayAdj < 0)
                  Text(
                    'Today: ${formatCurrency(todayAdj)}',
                    style: TextStyle(
                      color: LekoColors.labelRed.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(recoveryPlanServiceProvider).cancel(plan.id);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Cancel',
                style: TextStyle(
                    color: LekoColors.labelOrange, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  String _planLabel(String planType) {
    if (planType.contains('reduce_next_n_days')) return 'Reduce daily';
    if (planType.contains('reduce_weekends_only')) return 'Reduce weekends';
    if (planType.contains('push_goal_date')) return 'Push goal date';
    if (planType.contains('temp_switch_saving_style')) return 'Temp style';
    return 'Active';
  }
}
