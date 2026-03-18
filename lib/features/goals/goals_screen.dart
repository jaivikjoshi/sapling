import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/goals_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/leko_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../domain/models/enums.dart';
import 'goal_form_sheet.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      backgroundColor: LekoColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            floating: true,
            title: Text(
              'Goals',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: LekoColors.textPrimary,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  onPressed: () => _showForm(context),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: LekoColors.textPrimary,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ],
          ),
          goalsAsync.when(
            loading:
                () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
            error:
                (e, _) => SliverFillRemaining(
                  child: Center(child: Text('Error: $e')),
                ),
            data: (goals) {
              if (goals.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.flag_rounded,
                            size: 64,
                            color: LekoColors.support,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No goals yet.\nPlant a seed for the future.',
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: LekoColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final primaryId = settingsAsync.valueOrNull?.primaryGoalId;

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _GoalTile(
                      goal: goals[i],
                      isPrimary: goals[i].id == primaryId,
                    ),
                    childCount: goals.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {Goal? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: LekoColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => GoalFormSheet(existing: existing),
    );
  }
}

class _GoalTile extends ConsumerWidget {
  const _GoalTile({required this.goal, required this.isPrimary});

  final Goal goal;
  final bool isPrimary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat.yMMMd();
    final style = enumFromDb<SavingStyle>(goal.savingStyle, SavingStyle.values);
    final progress =
        goal.targetAmount > 0
            ? 0.0 // Progress is tracked by saved amount — stubbed until savings tracking
            : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GoalDetailScreen(goalId: goal.id),
                ),
              ),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: LekoColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        color: LekoColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPrimary)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'PRIMARY GOAL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: LekoColors.secondary,
                                ),
                              ),
                            ),
                          Text(
                            goal.name,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                              letterSpacing: -0.5,
                              color: LekoColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: LekoColors.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected:
                          (action) => _handleAction(context, ref, action),
                      itemBuilder:
                          (_) => [
                            if (!isPrimary)
                              const PopupMenuItem(
                                value: 'primary',
                                child: Text('Set as Primary'),
                              ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'archive',
                              child: Text('Archive'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(color: LekoColors.labelRed),
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(0), // Stubbed saved amount
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: LekoColors.textPrimary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        'of ${formatCurrency(goal.targetAmount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: LekoColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: LekoColors.divider.withValues(
                      alpha: 0.5,
                    ),
                    valueColor: AlwaysStoppedAnimation(
                      isPrimary
                          ? LekoColors.secondary
                          : LekoColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _IconChip(
                      icon: Icons.calendar_today_rounded,
                      label: dateFmt.format(goal.targetDate),
                    ),
                    const SizedBox(width: 8),
                    _IconChip(
                      icon: Icons.speed_rounded,
                      label: style.name,
                      color: _styleColor(style),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _styleColor(SavingStyle s) => switch (s) {
    SavingStyle.easy => LekoColors.labelGreen,
    SavingStyle.natural => LekoColors.labelOrange,
    SavingStyle.aggressive => LekoColors.labelRed,
  };

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final service = ref.read(goalsServiceProvider);
    switch (action) {
      case 'primary':
        await service.setPrimaryGoal(goal.id);
      case 'edit':
        if (context.mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => GoalFormSheet(existing: goal),
          );
        }
      case 'archive':
        await service.archive(goal.id);
      case 'delete':
        await service.delete(goal.id);
    }
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? LekoColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: effectiveColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Goal Detail Screen (separate widget, same file for nav simplicity)
// ──────────────────────────────────────────────
class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Goal Details')),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          final goal = goals.where((g) => g.id == goalId).firstOrNull;
          if (goal == null) {
            return const Center(child: Text('Goal not found.'));
          }
          return _GoalDetailBody(goal: goal);
        },
      ),
    );
  }
}

class _GoalDetailBody extends ConsumerWidget {
  const _GoalDetailBody({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat.yMMMd();
    final style = enumFromDb<SavingStyle>(goal.savingStyle, SavingStyle.values);
    final settingsAsync = ref.watch(settingsStreamProvider);
    final isPrimary = settingsAsync.valueOrNull?.primaryGoalId == goal.id;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          goal.name,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (isPrimary) ...[
          const SizedBox(height: 4),
          const Text(
            'Primary Goal',
            style: TextStyle(
              color: LekoColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 24),
        _DetailRow(
          label: 'Target Amount',
          value: formatCurrency(goal.targetAmount),
        ),
        _DetailRow(
          label: 'Target Date',
          value: dateFmt.format(goal.targetDate),
        ),
        _DetailRow(label: 'Saving Style', value: style.name),
        _DetailRow(label: 'Priority', value: '#${goal.priorityOrder + 1}'),
        const SizedBox(height: 24),
        if (!isPrimary)
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(goalsServiceProvider).setPrimaryGoal(goal.id);
            },
            icon: const Icon(Icons.star),
            label: const Text('Set as Primary Goal'),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: LekoColors.textSecondary),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
