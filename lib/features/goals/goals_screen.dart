import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/bills_providers.dart';
import '../../core/providers/goals_providers.dart';
import '../../core/providers/ledger_providers.dart';
import '../../core/providers/recurring_income_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/services/goal_feasibility_service.dart';
import '../../domain/services/goals_service.dart';
import '../../domain/services/projection_service.dart';
import 'goal_form_sheet.dart';

final goalInsightsProvider = FutureProvider<Map<String, GoalInsight>>((ref) async {
  final goals = ref.watch(goalsStreamProvider).valueOrNull ?? const <Goal>[];
  final settings = ref.watch(settingsStreamProvider).valueOrNull;

  ref.watch(balanceStreamProvider);
  ref.watch(billsStreamProvider);
  ref.watch(recurringIncomesProvider);

  if (goals.isEmpty || settings == null) return const {};

  final txnRepo = ref.read(transactionsRepositoryProvider);
  final incomeRepo = ref.read(recurringIncomeRepositoryProvider);
  final billsRepo = ref.read(billsRepositoryProvider);

  final balance = await txnRepo.computeBalance();
  final allTxns = await txnRepo.getAll();
  final schedules = await incomeRepo.getAll();
  final bills = await billsRepo.getAll();

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final incomeTxns = allTxns.where((t) => t.type == 'income').toList();
  final paidBillTxns = allTxns.where((t) => t.linkedBillId != null).toList();
  final baselineDailySpend = _computeBaselineDailySpend(
    allTxns: allTxns,
    windowDays: settings.spendingBaselineDays,
  );

  final result = <String, GoalInsight>{};

  for (final goal in goals) {
    final targetDay = DateTime(
      goal.targetDate.year,
      goal.targetDate.month,
      goal.targetDate.day,
    );
    final horizon = targetDay.difference(todayStart).inDays + 1;
    final daysToGoal = horizon < 1 ? 1 : horizon;
    final horizonEnd = DateTime(
      todayStart.year,
      todayStart.month,
      todayStart.day + daysToGoal,
    );

    final grossProjectedIncome = ProjectionService.projectIncome(
      start: todayStart,
      end: horizonEnd,
      confirmedIncome: incomeTxns,
      schedules: schedules,
    );
    final confirmedIncomeInWindow = incomeTxns
        .where((t) => !t.date.isBefore(todayStart) && t.date.isBefore(horizonEnd))
        .fold<double>(0, (sum, t) => sum + t.amount);
    final futureIncome = grossProjectedIncome - confirmedIncomeInWindow;

    final futureBills = ProjectionService.projectBills(
      start: todayStart,
      end: horizonEnd,
      bills: bills,
      paidBillTransactions: paidBillTxns,
    );

    final savingStyle = enumFromDb<SavingStyle>(
      goal.savingStyle,
      SavingStyle.values,
    );
    final feasibility = GoalFeasibilityService.compute(
      goal: goal,
      balance: balance,
      projectedIncome: futureIncome,
      projectedBills: futureBills,
      dailyVariableSpend: baselineDailySpend,
      savingStyleMultiplier: savingStyle.multiplier,
    );

    final currentTowardGoal = balance <= 0
        ? 0.0
        : math.min(balance, goal.targetAmount).toDouble();
    final remaining = math.max(0.0, goal.targetAmount - currentTowardGoal);
    final progress = goal.targetAmount <= 0
        ? 0.0
        : (currentTowardGoal / goal.targetAmount).clamp(0.0, 1.0);
    final dailyPaceNeeded = daysToGoal > 0 ? remaining / daysToGoal : remaining;
    final ratio = feasibility.need <= 0
        ? 2.0
        : feasibility.freeAfterObligations / feasibility.need;

    final status = !feasibility.isFeasible
        ? GoalRealism.unrealistic
        : ratio < 1.15
            ? GoalRealism.tight
            : GoalRealism.onTrack;

    result[goal.id] = GoalInsight(
      currentTowardGoal: currentTowardGoal,
      remainingAmount: remaining,
      progress: progress,
      daysLeft: daysToGoal,
      dailyPaceNeeded: dailyPaceNeeded,
      feasibility: feasibility,
      status: status,
    );
  }

  return result;
});

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final insightsAsync = ref.watch(goalInsightsProvider);

    return Scaffold(
      backgroundColor: _GoalsPalette.background,
      body: Stack(
        children: [
          const _GoalsBackdrop(),
          SafeArea(
            bottom: false,
            child: goalsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _GoalsPalette.teal),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Unable to load goals.\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _GoalsPalette.textSecondary),
                ),
              ),
              data: (goals) {
                if (goals.isEmpty) {
                  return _EmptyGoalsState(onAdd: () => _showForm(context));
                }

                final primaryId = settings?.primaryGoalId;
                Goal? primaryGoal;
                if (primaryId != null) {
                  for (final goal in goals) {
                    if (goal.id == primaryId) {
                      primaryGoal = goal;
                      break;
                    }
                  }
                }

                final otherGoals = goals
                    .where((goal) => goal.id != primaryGoal?.id)
                    .toList();
                final totalTarget = goals.fold<double>(
                  0,
                  (sum, goal) => sum + goal.targetAmount,
                );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 116),
                  children: [
                    _GoalsHeader(
                      activeGoalCount: goals.length,
                      totalTarget: totalTarget,
                      onAdd: () => _showForm(context),
                    ),
                    const SizedBox(height: 22),
                    if (primaryGoal != null) ...[
                      _PrimaryGoalSection(
                        goal: primaryGoal!,
                        insight: insightsAsync.valueOrNull?[primaryGoal!.id],
                        onOpen: () => _openDetail(context, primaryGoal!.id),
                        onEdit: () => _showForm(context, existing: primaryGoal!),
                      ),
                      const SizedBox(height: 18),
                    ] else ...[
                      const _NoPrimaryGoalBanner(),
                      const SizedBox(height: 18),
                    ],
                    if (otherGoals.isNotEmpty) ...[
                      const _SectionLabel(
                        title: 'Other goals',
                        subtitle: 'Reorder them to keep your priorities clear.',
                      ),
                      const SizedBox(height: 12),
                      _ReorderableGoalsSection(
                        goals: otherGoals,
                        primaryGoalId: primaryGoal?.id,
                        insights: insightsAsync.valueOrNull ?? const {},
                        onOpenGoal: (goalId) => _openDetail(context, goalId),
                        onEditGoal: (goal) => _showForm(context, existing: goal),
                      ),
                    ],
                    if (goals.length == 1) ...[
                      const SizedBox(height: 18),
                      _SingleGoalSupportCard(
                        primaryExists: primaryGoal != null,
                        onAddGoal: () => _showForm(context),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, {Goal? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _GoalsPalette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => GoalFormSheet(existing: existing),
    );
  }

  void _openDetail(BuildContext context, String goalId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: goalId)),
    );
  }
}

class _GoalsBackdrop extends StatelessWidget {
  const _GoalsBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071214),
            Color(0xFF0B181B),
            Color(0xFF0D1718),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -30,
            child: _GlowOrb(
              size: 220,
              color: _GoalsPalette.teal.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 180,
            left: -50,
            child: _GlowOrb(
              size: 170,
              color: _GoalsPalette.gold.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _GoalsHeader extends StatelessWidget {
  const _GoalsHeader({
    required this.activeGoalCount,
    required this.totalTarget,
    required this.onAdd,
  });

  final int activeGoalCount;
  final double totalTarget;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Goals',
                style: TextStyle(
                  color: _GoalsPalette.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$activeGoalCount active ${activeGoalCount == 1 ? 'goal' : 'goals'} • ${formatCurrency(totalTarget)} targeted',
                style: const TextStyle(
                  color: _GoalsPalette.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _AddGoalButton(onTap: onAdd),
      ],
    );
  }
}

class _AddGoalButton extends StatelessWidget {
  const _AddGoalButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _GoalsPalette.surfaceRaised.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _GoalsPalette.outline),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: _GoalsPalette.textPrimary, size: 18),
              SizedBox(width: 6),
              Text(
                'New',
                style: TextStyle(
                  color: _GoalsPalette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _GoalsPalette.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _GoalsPalette.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _PrimaryGoalSection extends ConsumerWidget {
  const _PrimaryGoalSection({
    required this.goal,
    required this.insight,
    required this.onOpen,
    required this.onEdit,
  });

  final Goal goal;
  final GoalInsight? insight;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = enumFromDb<SavingStyle>(goal.savingStyle, SavingStyle.values);
    final status = insight?.status ?? GoalRealism.tight;
    final statusText = _statusLabel(status);
    final statusColor = _statusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(34),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF143136), Color(0xFF0E2024)],
            ),
            border: Border.all(color: _GoalsPalette.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: _GoalsPalette.teal.withValues(alpha: 0.10),
                blurRadius: 28,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Badge(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Primary',
                    color: _GoalsPalette.gold,
                  ),
                  const Spacer(),
                  _HeroActionButton(
                    icon: Icons.edit_outlined,
                    onTap: onEdit,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                goal.name,
                style: const TextStyle(
                  color: _GoalsPalette.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.0,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrency(insight?.currentTowardGoal ?? 0),
                    style: const TextStyle(
                      color: _GoalsPalette.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'of ${formatCurrency(goal.targetAmount)}',
                      style: const TextStyle(
                        color: _GoalsPalette.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: insight?.progress ?? 0,
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(_GoalsPalette.teal),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetaPill(
                    icon: Icons.calendar_today_rounded,
                    label: DateFormat.yMMMd().format(goal.targetDate),
                  ),
                  _MetaPill(
                    icon: Icons.tune_rounded,
                    label: _savingStyleLabel(style),
                    color: _styleColor(style),
                  ),
                  _MetaPill(
                    icon: _statusIcon(status),
                    label: statusText,
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _InsightBlock(
                      label: 'Remaining',
                      value: formatCurrency(insight?.remainingAmount ?? goal.targetAmount),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InsightBlock(
                      label: 'Time left',
                      value: '${insight?.daysLeft ?? 0} days',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InsightBlock(
                      label: 'Pace needed',
                      value: '${formatCurrency(insight?.dailyPaceNeeded ?? 0)}/day',
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              if (insight?.feasibility.suggestedDate != null) ...[
                const SizedBox(height: 16),
                _QuietNote(
                  icon: Icons.event_available_rounded,
                  text:
                      'Suggested target date: ${DateFormat.yMMMd().format(insight!.feasibility.suggestedDate!)}',
                ),
              ] else ...[
                const SizedBox(height: 16),
                const _QuietNote(
                  icon: Icons.home_filled,
                  text: 'Home will use this goal when you switch into goal planning mode.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoPrimaryGoalBanner extends StatelessWidget {
  const _NoPrimaryGoalBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _GoalsPalette.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _GoalsPalette.outline),
      ),
      child: const Row(
        children: [
          Icon(Icons.flag_circle_rounded, color: _GoalsPalette.gold, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pick a primary goal to give Home a clearer planning focus.',
              style: TextStyle(
                color: _GoalsPalette.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleGoalSupportCard extends StatelessWidget {
  const _SingleGoalSupportCard({
    required this.primaryExists,
    required this.onAddGoal,
  });

  final bool primaryExists;
  final VoidCallback onAddGoal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _GoalsPalette.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _GoalsPalette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keep this screen useful',
            style: TextStyle(
              color: _GoalsPalette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            primaryExists
                ? 'Your primary goal already powers planning on Home. Adding another goal later is a good way to separate near-term needs from longer-term ambition.'
                : 'Once one goal is marked primary, Home can plan around it more intentionally. You can still keep this page simple with just one goal.',
            style: const TextStyle(
              color: _GoalsPalette.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: onAddGoal,
            style: TextButton.styleFrom(
              foregroundColor: _GoalsPalette.teal,
              padding: EdgeInsets.zero,
            ),
            child: const Text(
              'Add another goal',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReorderableGoalsSection extends ConsumerStatefulWidget {
  const _ReorderableGoalsSection({
    required this.goals,
    required this.primaryGoalId,
    required this.insights,
    required this.onOpenGoal,
    required this.onEditGoal,
  });

  final List<Goal> goals;
  final String? primaryGoalId;
  final Map<String, GoalInsight> insights;
  final ValueChanged<String> onOpenGoal;
  final ValueChanged<Goal> onEditGoal;

  @override
  ConsumerState<_ReorderableGoalsSection> createState() =>
      _ReorderableGoalsSectionState();
}

class _ReorderableGoalsSectionState
    extends ConsumerState<_ReorderableGoalsSection> {
  late List<Goal> _goals;

  @override
  void initState() {
    super.initState();
    _goals = List.of(widget.goals);
  }

  @override
  void didUpdateWidget(covariant _ReorderableGoalsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.goals.map((g) => g.id).join('|');
    final newIds = widget.goals.map((g) => g.id).join('|');
    if (oldIds != newIds) {
      _goals = List.of(widget.goals);
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _goals.removeAt(oldIndex);
      _goals.insert(newIndex, item);
    });

    final service = ref.read(goalsServiceProvider);
    for (var i = 0; i < _goals.length; i++) {
      final goal = _goals[i];
      final style = enumFromDb<SavingStyle>(goal.savingStyle, SavingStyle.values);
      await service.update(
        id: goal.id,
        name: goal.name,
        targetAmount: goal.targetAmount,
        targetDate: goal.targetDate,
        savingStyle: style,
        priorityOrder: i + 1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: _onReorder,
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        return Padding(
          key: ValueKey(goal.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: _GoalListCard(
            goal: goal,
            insight: widget.insights[goal.id],
            isPrimary: goal.id == widget.primaryGoalId,
            onOpen: () => widget.onOpenGoal(goal.id),
            onEdit: () => widget.onEditGoal(goal),
            dragHandle: ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.drag_indicator_rounded,
                  color: _GoalsPalette.textMuted,
                  size: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GoalListCard extends ConsumerWidget {
  const _GoalListCard({
    required this.goal,
    required this.insight,
    required this.isPrimary,
    required this.onOpen,
    required this.onEdit,
    required this.dragHandle,
  });

  final Goal goal;
  final GoalInsight? insight;
  final bool isPrimary;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = enumFromDb<SavingStyle>(goal.savingStyle, SavingStyle.values);
    final status = insight?.status ?? GoalRealism.tight;
    final statusColor = _statusColor(status);
    final service = ref.read(goalsServiceProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _GoalsPalette.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _GoalsPalette.outline),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _styleColor(style).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.flag_rounded,
                      color: _styleColor(style),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                goal.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _GoalsPalette.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            if (isPrimary) ...[
                              const SizedBox(width: 8),
                              const _Badge(
                                icon: Icons.star_rounded,
                                label: 'Primary',
                                color: _GoalsPalette.gold,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MetaPill(
                              icon: Icons.tune_rounded,
                              label: _savingStyleLabel(style),
                              color: _styleColor(style),
                            ),
                            _MetaPill(
                              icon: _statusIcon(status),
                              label: _statusLabel(status),
                              color: statusColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  dragHandle,
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    color: _GoalsPalette.surfaceRaised,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: _GoalsPalette.textMuted,
                    ),
                    onSelected: (action) async {
                      switch (action) {
                        case 'primary':
                          await service.setPrimaryGoal(goal.id);
                        case 'edit':
                          onEdit();
                        case 'archive':
                          await service.archive(goal.id);
                      }
                    },
                    itemBuilder: (_) => [
                      if (!isPrimary)
                        const PopupMenuItem(
                          value: 'primary',
                          child: Text('Set as primary'),
                        ),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'archive',
                        child: Text('Archive'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatCurrency(insight?.currentTowardGoal ?? 0)} of ${formatCurrency(goal.targetAmount)}',
                      style: const TextStyle(
                        color: _GoalsPalette.textSoft,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isPrimary ? null : () async => service.setPrimaryGoal(goal.id),
                    icon: Icon(
                      isPrimary ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isPrimary ? _GoalsPalette.gold : _GoalsPalette.textMuted,
                      size: 20,
                    ),
                    tooltip: isPrimary ? 'Primary goal' : 'Set as primary',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: insight?.progress ?? 0,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _CompactInfo(
                      label: 'Remaining',
                      value: formatCurrency(insight?.remainingAmount ?? goal.targetAmount),
                    ),
                  ),
                  Expanded(
                    child: _CompactInfo(
                      label: 'Target',
                      value: DateFormat.MMMd().format(goal.targetDate),
                    ),
                  ),
                  Expanded(
                    child: _CompactInfo(
                      label: 'Pace',
                      value: '${formatCurrency(insight?.dailyPaceNeeded ?? 0)}/day',
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              if (insight?.feasibility.suggestedDate != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Suggested date: ${DateFormat.yMMMd().format(insight!.feasibility.suggestedDate!)}',
                    style: const TextStyle(
                      color: _GoalsPalette.alertSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGoalsState extends StatelessWidget {
  const _EmptyGoalsState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 116),
      children: [
        _GoalsHeader(activeGoalCount: 0, totalTarget: 0, onAdd: onAdd),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _GoalsPalette.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _GoalsPalette.outline),
          ),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _GoalsPalette.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.flag_circle_rounded,
                  size: 34,
                  color: _GoalsPalette.gold,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Give your money somewhere meaningful to go.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _GoalsPalette.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Add your first goal and Leko can start shaping daily guidance around it. Once a goal is marked primary, Home planning becomes much more intentional.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _GoalsPalette.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: _GoalsPalette.teal,
                  foregroundColor: _GoalsPalette.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Create your first goal',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: _GoalsPalette.textPrimary, size: 18),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.color = _GoalsPalette.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightBlock extends StatelessWidget {
  const _InsightBlock({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _GoalsPalette.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _GoalsPalette.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CompactInfo extends StatelessWidget {
  const _CompactInfo({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _GoalsPalette.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _GoalsPalette.textSoft,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _QuietNote extends StatelessWidget {
  const _QuietNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _GoalsPalette.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _GoalsPalette.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GoalInsight {
  const GoalInsight({
    required this.currentTowardGoal,
    required this.remainingAmount,
    required this.progress,
    required this.daysLeft,
    required this.dailyPaceNeeded,
    required this.feasibility,
    required this.status,
  });

  final double currentTowardGoal;
  final double remainingAmount;
  final double progress;
  final int daysLeft;
  final double dailyPaceNeeded;
  final GoalFeasibilityResult feasibility;
  final GoalRealism status;
}

enum GoalRealism { onTrack, tight, unrealistic }

double _computeBaselineDailySpend({
  required List<Transaction> allTxns,
  required int windowDays,
}) {
  final now = DateTime.now();
  final cutoff = DateTime(now.year, now.month, now.day - windowDays);
  double variableSum = 0;
  for (final txn in allTxns) {
    if (txn.type == 'expense' &&
        txn.linkedBillId == null &&
        !txn.date.isBefore(cutoff)) {
      variableSum += txn.amount;
    }
  }
  return windowDays > 0 ? variableSum / windowDays : 0;
}

String _savingStyleLabel(SavingStyle style) => switch (style) {
      SavingStyle.easy => 'Easy',
      SavingStyle.natural => 'Natural',
      SavingStyle.aggressive => 'Aggressive',
    };

String _statusLabel(GoalRealism status) => switch (status) {
      GoalRealism.onTrack => 'On track',
      GoalRealism.tight => 'Tight',
      GoalRealism.unrealistic => 'Unrealistic',
    };

IconData _statusIcon(GoalRealism status) => switch (status) {
      GoalRealism.onTrack => Icons.check_circle_rounded,
      GoalRealism.tight => Icons.timelapse_rounded,
      GoalRealism.unrealistic => Icons.warning_amber_rounded,
    };

Color _statusColor(GoalRealism status) => switch (status) {
      GoalRealism.onTrack => _GoalsPalette.teal,
      GoalRealism.tight => _GoalsPalette.gold,
      GoalRealism.unrealistic => _GoalsPalette.alert,
    };

Color _styleColor(SavingStyle style) => switch (style) {
      SavingStyle.easy => const Color(0xFF73D1BE),
      SavingStyle.natural => const Color(0xFFE0B980),
      SavingStyle.aggressive => const Color(0xFFE08E82),
    };

abstract final class _GoalsPalette {
  static const background = Color(0xFF071214);
  static const surface = Color(0xFF0E1A1D);
  static const surfaceRaised = Color(0xFF15252A);
  static const outline = Color(0x2237A29C);
  static const teal = Color(0xFF58B8A2);
  static const gold = Color(0xFFE0B980);
  static const alert = Color(0xFFD88478);
  static const alertSoft = Color(0xFFF2B2A7);
  static const textPrimary = Color(0xFFF7F2E8);
  static const textSoft = Color(0xFFD9E3DF);
  static const textSecondary = Color(0xFF97ACA8);
  static const textMuted = Color(0xFF768A87);
}

// Goal Detail Screen
class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsStreamProvider);
    final insights = ref.watch(goalInsightsProvider).valueOrNull ?? const {};
    final settings = ref.watch(settingsStreamProvider).valueOrNull;

    return Scaffold(
      backgroundColor: _GoalsPalette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: _GoalsPalette.textPrimary,
        title: const Text('Goal'),
      ),
      body: goalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _GoalsPalette.teal),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: _GoalsPalette.textSecondary)),
        ),
        data: (goals) {
          Goal? goal;
          for (final item in goals) {
            if (item.id == goalId) {
              goal = item;
              break;
            }
          }
          if (goal == null) {
            return const Center(
              child: Text(
                'Goal not found.',
                style: TextStyle(color: _GoalsPalette.textSecondary),
              ),
            );
          }
          final resolvedGoal = goal!;
          final style = enumFromDb<SavingStyle>(
            resolvedGoal.savingStyle,
            SavingStyle.values,
          );
          final isPrimary = settings?.primaryGoalId == resolvedGoal.id;
          final insight = insights[resolvedGoal.id];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                resolvedGoal.name,
                style: const TextStyle(
                  color: _GoalsPalette.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.0,
                ),
              ),
              if (isPrimary) ...[
                const SizedBox(height: 8),
                const _Badge(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Primary goal',
                  color: _GoalsPalette.gold,
                ),
              ],
              const SizedBox(height: 24),
              _RecapCard(
                label: 'Target amount',
                value: formatCurrency(resolvedGoal.targetAmount),
              ),
              _RecapCard(
                label: 'Target date',
                value: DateFormat.yMMMd().format(resolvedGoal.targetDate),
              ),
              _RecapCard(
                label: 'Saving style',
                value: _savingStyleLabel(style),
              ),
              if (insight != null) ...[
                _RecapCard(
                  label: 'Realism',
                  value: _statusLabel(insight.status),
                ),
                _RecapCard(
                  label: 'Amount remaining',
                  value: formatCurrency(insight.remainingAmount),
                ),
              ],
              if (!isPrimary) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(goalsServiceProvider)
                        .setPrimaryGoal(resolvedGoal.id);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _GoalsPalette.teal,
                    foregroundColor: _GoalsPalette.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.star_rounded),
                  label: const Text(
                    'Set as primary goal',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RecapCard extends StatelessWidget {
  const _RecapCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _GoalsPalette.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _GoalsPalette.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: _GoalsPalette.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _GoalsPalette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
