import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/goals_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/sapling_database.dart';
import '../../domain/models/enums.dart';
import 'goal_form_sheet.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);
    final settingsAsync = ref.watch(settingsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'goals_fab',
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          if (goals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No goals yet.\nTap + to create your first goal.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final primaryId = settingsAsync.valueOrNull?.primaryGoalId;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (ctx, i) => _GoalTile(
              goal: goals[i],
              isPrimary: goals[i].id == primaryId,
            ),
          );
        },
      ),
    );
  }

  void _showForm(BuildContext context, {Goal? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
    final progress = goal.targetAmount > 0
        ? 0.0 // Progress is tracked by saved amount — stubbed until savings tracking
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GoalDetailScreen(goalId: goal.id),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isPrimary)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: SaplingColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PRIMARY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: SaplingColors.secondary,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      goal.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) =>
                        _handleAction(context, ref, action),
                    itemBuilder: (_) => [
                      if (!isPrimary)
                        const PopupMenuItem(
                          value: 'primary',
                          child: Text('Set as Primary'),
                        ),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'archive', child: Text('Archive')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: SaplingColors.labelRed)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Chip(label: formatCurrency(goal.targetAmount)),
                  const SizedBox(width: 8),
                  _Chip(label: dateFmt.format(goal.targetDate)),
                  const SizedBox(width: 8),
                  _Chip(label: style.name, color: _styleColor(style)),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: SaplingColors.divider,
                valueColor: AlwaysStoppedAnimation(
                    isPrimary ? SaplingColors.secondary : SaplingColors.support),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _styleColor(SavingStyle s) => switch (s) {
        SavingStyle.easy => SaplingColors.labelGreen,
        SavingStyle.natural => SaplingColors.labelOrange,
        SavingStyle.aggressive => SaplingColors.labelRed,
      };

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action) async {
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? SaplingColors.textSecondary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color ?? SaplingColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
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
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (isPrimary) ...[
          const SizedBox(height: 4),
          const Text('Primary Goal',
              style: TextStyle(
                  color: SaplingColors.secondary, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 24),
        _DetailRow(label: 'Target Amount',
            value: formatCurrency(goal.targetAmount)),
        _DetailRow(label: 'Target Date',
            value: dateFmt.format(goal.targetDate)),
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
          Text(label,
              style: const TextStyle(color: SaplingColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
