import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/allowance_providers.dart';
import '../../../core/theme/leko_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/services/allowance_engine.dart';
import '../../../domain/services/goal_feasibility_service.dart';

class AllowanceCard extends ConsumerWidget {
  const AllowanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(effectiveAllowanceModeProvider);

    return switch (mode) {
      AllowanceMode.paycheck => const _PaycheckCard(),
      AllowanceMode.goal => const _GoalCard(),
    };
  }
}

// ── Mode toggle chip ──

class _ModeToggle extends ConsumerWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(effectiveAllowanceModeProvider);

    return GestureDetector(
      onTap: () {
        final next = mode == AllowanceMode.paycheck
            ? AllowanceMode.goal
            : AllowanceMode.paycheck;
        ref.read(allowanceModeOverrideProvider.notifier).state = next;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: LekoColors.secondary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mode == AllowanceMode.paycheck ? 'To Paycheck' : 'To Goal',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: LekoColors.secondary),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.swap_horiz,
                size: 14, color: LekoColors.secondary),
          ],
        ),
      ),
    );
  }
}

// ── Paycheck card ──

class _PaycheckCard extends ConsumerWidget {
  const _PaycheckCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(paycheckAllowanceProvider);

    return resultAsync.when(
      loading: () => _buildShell(context, loading: true),
      error: (e, _) => _buildShell(context, error: e.toString()),
      data: (result) {
        if (result == null) return _buildShell(context, loading: true);
        return _buildPaycheckData(context, result);
      },
    );
  }

  Widget _buildPaycheckData(BuildContext context, PaycheckAllowanceResult r) {
    final dateFmt = DateFormat.MMMd();
    return Card(
      color: LekoColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('You can spend today',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: LekoColors.background, letterSpacing: 0.2)),
                const _ModeToggle(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              formatCurrency(r.allowanceToday),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 56,
                    letterSpacing: -2.0,
                    color: Colors.white,
                    height: 1.0,
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MiniStatBlock(
                  label: 'Banked',
                  value: formatCurrency(r.bankedAllowance),
                  valueColor: r.bankedAllowance >= 0
                      ? LekoColors.secondary
                      : LekoColors.accent,
                ),
                _MiniStatBlock(
                  label: 'Days left',
                  value: '${r.daysLeft}',
                  valueColor: Colors.white,
                ),
                _MiniStatBlock(
                  label: 'Cycle',
                  value: '${dateFmt.format(r.cycleWindow.start)} – '
                      '${dateFmt.format(r.cycleWindow.end)}',
                  valueColor: Colors.white,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShell(BuildContext context,
      {bool loading = false, String? error}) {
    return Card(
      color: LekoColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('You can spend today',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: LekoColors.background, letterSpacing: 0.2)),
                const _ModeToggle(),
              ],
            ),
            const SizedBox(height: 16),
            if (loading)
              const SizedBox(
                height: 56, width: 150,
                child: LinearProgressIndicator(
                  color: LekoColors.secondary,
                  backgroundColor: LekoColors.support,
                ),
              )
            else if (error != null)
              Text(error,
                  style: const TextStyle(color: LekoColors.labelRed)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Goal card ──

class _GoalCard extends ConsumerWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(goalAllowanceProvider);

    return resultAsync.when(
      loading: () => _buildGoalShell(context, loading: true),
      error: (e, _) => _buildGoalShell(context, error: e.toString()),
      data: (result) {
        if (result == null) return _buildNoGoal(context);
        return _buildGoalData(context, result);
      },
    );
  }

  Widget _buildGoalData(BuildContext context, GoalAllowanceResult r) {
    final dateFmt = DateFormat.MMMd();
    return Card(
      color: LekoColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('You can spend today',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: LekoColors.background, letterSpacing: 0.2)),
                const _ModeToggle(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              formatCurrency(r.allowanceToday),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700, 
                    fontSize: 56,
                    letterSpacing: -2.0,
                    color: Colors.white,
                    height: 1.0,
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MiniStatBlock(
                  label: 'Target',
                  value: formatCurrency(r.goal.targetAmount),
                  valueColor: Colors.white,
                ),
                _MiniStatBlock(
                  label: 'By',
                  value: dateFmt.format(r.goal.targetDate),
                  valueColor: Colors.white,
                ),
                _MiniStatBlock(
                  label: 'Banked',
                  value: formatCurrency(r.bankedAllowance),
                  valueColor: r.bankedAllowance >= 0
                      ? LekoColors.secondary
                      : LekoColors.accent,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ],
            ),
            if (!r.feasibility.isFeasible) ...[
              const SizedBox(height: 16),
              _FeasibilityWarning(feasibility: r.feasibility),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoGoal(BuildContext context) {
    return Card(
      color: LekoColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('You can spend today',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: LekoColors.background, letterSpacing: 0.2)),
                const _ModeToggle(),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'No primary goal set.\nGo to Goals tab and set one.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: LekoColors.background.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalShell(BuildContext context,
      {bool loading = false, String? error}) {
    return Card(
      color: LekoColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('You can spend today',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: LekoColors.background, letterSpacing: 0.2)),
                const _ModeToggle(),
              ],
            ),
            const SizedBox(height: 16),
            if (loading)
              const SizedBox(
                height: 56, width: 150,
                child: LinearProgressIndicator(
                  color: LekoColors.secondary,
                  backgroundColor: LekoColors.support,
                ),
              )
            else if (error != null)
              Text(error,
                  style: const TextStyle(color: LekoColors.labelRed)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Feasibility warning ──

class _FeasibilityWarning extends StatelessWidget {
  const _FeasibilityWarning({required this.feasibility});
  final GoalFeasibilityResult feasibility;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: LekoColors.labelRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Short by ${formatCurrency(feasibility.deficit)}',
            style: const TextStyle(
              color: LekoColors.labelRed,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (feasibility.suggestedDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Suggested date: ${dateFmt.format(feasibility.suggestedDate!)}',
                style: TextStyle(
                  color: LekoColors.accent.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared info row ──

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                    color: LekoColors.background.withValues(alpha: 0.7))),
        Flexible(
          child: Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _MiniStatBlock extends StatelessWidget {
  const _MiniStatBlock({
    required this.label,
    required this.value,
    required this.valueColor,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final Color valueColor;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: LekoColors.background.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
