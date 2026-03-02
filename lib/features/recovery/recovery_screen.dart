import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/recovery_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/db/sapling_database.dart';
import '../../domain/services/recovery_plan_service.dart';

class RecoveryScreen extends ConsumerWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeRecoveryPlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Plan')),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (plan) {
          if (plan == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No active recovery plan.\n\n'
                  'If you overspend on an expense, '
                  'you\'ll be prompted to pick a recovery plan.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _PlanDetail(plan: plan);
        },
      ),
    );
  }
}

class _PlanDetail extends ConsumerWidget {
  const _PlanDetail({required this.plan});
  final RecoveryPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = RecoveryPlanService.buildSchedule(plan);
    final dateFmt = DateFormat.MMMd();
    final todayAdj = RecoveryPlanService.computeTodayAdjustment(plan);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overspend Amount',
                    style: TextStyle(color: SaplingColors.textSecondary)),
                Text(
                  formatCurrency(plan.overspendAmount),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: SaplingColors.labelRed,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text('Today\'s adjustment',
                    style: TextStyle(color: SaplingColors.textSecondary)),
                Text(
                  formatCurrency(todayAdj),
                  style: TextStyle(
                    color: todayAdj < 0
                        ? SaplingColors.labelRed
                        : SaplingColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (schedule.isNotEmpty) ...[
          Text('Adjustment Schedule',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...schedule.map((adj) => ListTile(
                dense: true,
                leading: Icon(
                  _isToday(adj.date) ? Icons.today : Icons.calendar_today,
                  size: 18,
                  color: _isToday(adj.date)
                      ? SaplingColors.labelRed
                      : SaplingColors.textSecondary,
                ),
                title: Text(dateFmt.format(adj.date)),
                trailing: Text(
                  formatCurrency(adj.adjustment),
                  style: const TextStyle(
                      color: SaplingColors.labelRed,
                      fontWeight: FontWeight.w600),
                ),
              )),
        ],
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () async {
            await ref.read(recoveryPlanServiceProvider).cancel(plan.id);
          },
          style: OutlinedButton.styleFrom(
              foregroundColor: SaplingColors.labelRed),
          child: const Text('Cancel Recovery Plan'),
        ),
      ],
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}
