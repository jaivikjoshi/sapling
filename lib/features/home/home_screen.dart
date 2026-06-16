import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/allowance_providers.dart';
import '../../core/providers/badge_providers.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/bills_providers.dart';
import '../../core/providers/goals_providers.dart';
import '../../core/providers/ledger_providers.dart';
import '../../core/providers/profile_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/db/leko_database.dart';
import '../../domain/integrations/product_foundations.dart';
import '../../domain/models/enums.dart';
import '../goals/goals_screen.dart' show GoalInsight, goalInsightsProvider;

final _currentWeekTransactionsProvider = StreamProvider<List<Transaction>>((
  ref,
) {
  final now = DateTime.now();
  final start = _startOfWeek(now);
  final end = start.add(const Duration(days: 7));
  return ref.watch(ledgerServiceProvider).watchByDateRange(start, end);
});

final _todayTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final now = DateTime.now();
  final start = _startOfDay(now);
  final end = start.add(const Duration(days: 1));
  return ref.watch(ledgerServiceProvider).watchByDateRange(start, end);
});

final _yesterdayTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final today = _startOfDay(DateTime.now());
  final start = today.subtract(const Duration(days: 1));
  final end = today;
  return ref.watch(ledgerServiceProvider).watchByDateRange(start, end);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _HomePalette.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 128),
          children: [
            _Header(onNotifications: () => context.push('/closeout')),
            const SizedBox(height: 22),
            const _WeeklySummaryCard(),
            const SizedBox(height: 18),
            _QuickActionsRow(
              onAddExpense: () => context.push('/add-expense'),
              onAddIncome: () => context.push('/add-income'),
              onAddGoal: () => context.go('/goals?add=1'),
            ),
            const SizedBox(height: 18),
            const _WeeklySpendingCard(),
            const SizedBox(height: 24),
            _UpcomingBillsSection(onViewAll: () => context.push('/bills')),
            const SizedBox(height: 24),
            const _BadgesSection(),
            const SizedBox(height: 24),
            _GoalProgressSection(onViewAll: () => context.go('/goals')),
            const SizedBox(height: 24),
            _RecentActivitySection(
              onViewAll: () => context.push('/transactions'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgesSection extends ConsumerWidget {
  const _BadgesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earned = ref.watch(earnedBadgesProvider);
    final badges = LocalBadgeId.values.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Personal badges',
          actionLabel: 'Local only',
          onTap: () {},
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return _BadgePill(
                label: _badgeLabel(badge),
                icon: _badgeIcon(badge),
                earned: earned.contains(badge),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.label,
    required this.icon,
    required this.earned,
  });

  final String label;
  final IconData icon;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: earned ? const Color(0xFFEAF6F2) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: earned ? _HomePalette.mintAccent : _HomePalette.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color:
                earned ? _HomePalette.mintAccent : _HomePalette.textSecondary,
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  earned
                      ? _HomePalette.textPrimary
                      : _HomePalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.onNotifications});

  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(profileServiceProvider);
    final firstName = profile.firstName(user);
    final greetingName = firstName.isEmpty ? 'there' : firstName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, $greetingName',
                style: const TextStyle(
                  color: _HomePalette.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Today\'s money',
                style: TextStyle(
                  color: _HomePalette.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: onNotifications,
        ),
      ],
    );
  }
}

class _WeeklySummaryCard extends ConsumerWidget {
  const _WeeklySummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(effectiveAllowanceModeProvider);
    final paycheck = ref.watch(paycheckAllowanceProvider).valueOrNull;
    final goal = ref.watch(goalAllowanceProvider).valueOrNull;
    final upcomingBills =
        ref.watch(upcomingBillsProvider).valueOrNull ?? const [];
    final allowance = switch (mode) {
      AllowanceMode.paycheck => paycheck?.dailyAllowance,
      AllowanceMode.goal => goal?.dailyAllowance,
    };
    final remainingToday = switch (mode) {
      AllowanceMode.paycheck => paycheck?.remainingToday,
      AllowanceMode.goal => goal?.remainingToday,
    };
    final todaySpend = switch (mode) {
      AllowanceMode.paycheck => paycheck?.todaySpend,
      AllowanceMode.goal => goal?.todaySpend,
    };
    final isOverToday = remainingToday != null && remainingToday < 0;

    final nextBill = [...upcomingBills]
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final bill = nextBill.isEmpty ? null : nextBill.first;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: _HomePalette.summaryCard,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x42132440),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isOverToday ? 'OVER TODAY' : 'SAFE TO SPEND TODAY',
                  style: const TextStyle(
                    color: _HomePalette.summaryMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.9,
                  ),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            remainingToday != null
                ? formatCurrency(remainingToday.abs())
                : '--',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.today_rounded,
                size: 18,
                color: _HomePalette.positive,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _dailyPacingLabel(
                    remainingToday: remainingToday,
                    todaySpend: todaySpend,
                    dailyAllowance: allowance,
                  ),
                  style: const TextStyle(
                    color: _HomePalette.positive,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _SummaryMiniPanel(
                  title: 'Daily budget',
                  value:
                      allowance == null
                          ? 'Not ready'
                          : formatCurrency(allowance),
                  subtitle:
                      todaySpend == null
                          ? 'Today\'s spend will appear here'
                          : '${formatCurrency(todaySpend)} spent today',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryMiniPanel(
                  title: 'Next bill',
                  value:
                      bill == null
                          ? 'No bill due'
                          : '${bill.name} • ${formatCurrency(bill.amount)}',
                  subtitle:
                      bill == null
                          ? 'You\'re clear right now'
                          : _billDueLabel(bill.nextDueDate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMiniPanel extends StatelessWidget {
  const _SummaryMiniPanel({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _HomePalette.summaryMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: _HomePalette.summaryMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onAddGoal,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onAddGoal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            label: 'Expense',
            icon: Icons.add_rounded,
            onTap: onAddExpense,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            label: 'Income',
            icon: Icons.payments_outlined,
            background: _HomePalette.incomeCard,
            iconAccent: _HomePalette.incomeAccent,
            onTap: onAddIncome,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            label: 'Goal',
            icon: Icons.gps_fixed_rounded,
            background: _HomePalette.mintCard,
            iconAccent: _HomePalette.mintAccent,
            onTap: onAddGoal,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
    this.background = Colors.white,
    this.iconAccent = _HomePalette.iconCircle,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color iconAccent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _HomePalette.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _HomePalette.iconCircle,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconAccent, size: 17),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _HomePalette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklySpendingCard extends ConsumerWidget {
  const _WeeklySpendingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWeek =
        ref.watch(_currentWeekTransactionsProvider).valueOrNull ?? const [];
    final today = ref.watch(_todayTransactionsProvider).valueOrNull ?? const [];
    final yesterday =
        ref.watch(_yesterdayTransactionsProvider).valueOrNull ?? const [];

    final currentExpense = today
        .where((txn) => txn.type == 'expense')
        .fold<double>(0, (sum, txn) => sum + txn.amount);
    final previousExpense = yesterday
        .where((txn) => txn.type == 'expense')
        .fold<double>(0, (sum, txn) => sum + txn.amount);
    final trend =
        previousExpense <= 0
            ? null
            : ((currentExpense - previousExpense) / previousExpense * 100);
    final bars = _weeklySpendBars(currentWeek);
    final todayIndex = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spending today',
                      style: TextStyle(
                        color: _HomePalette.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatCurrency(currentExpense)} so far',
                      style: const TextStyle(
                        color: _HomePalette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _trendText(trend),
                style: TextStyle(
                  color:
                      trend == null || trend <= 0
                          ? _HomePalette.positive
                          : _HomePalette.alert,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < bars.length; i++) ...[
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 14,
                        height: math.max(bars[i], 6),
                        decoration: BoxDecoration(
                          color:
                              i == todayIndex
                                  ? _HomePalette.summaryCard
                                  : _HomePalette.chartBar,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _WeekdayLabel('M'),
              _WeekdayLabel('T'),
              _WeekdayLabel('W'),
              _WeekdayLabel('T'),
              _WeekdayLabel('F'),
              _WeekdayLabel('S'),
              _WeekdayLabel('S'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _HomePalette.textSecondary, fontSize: 10),
      ),
    );
  }
}

class _UpcomingBillsSection extends ConsumerWidget {
  const _UpcomingBillsSection({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills =
        ref.watch(upcomingBillsProvider).valueOrNull ?? const <Bill>[];
    final sorted = [...bills]
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final visible = sorted.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Upcoming bills',
          actionLabel: 'View all',
          onTap: onViewAll,
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          const _EmptyCard(message: 'No upcoming bills right now.')
        else
          Column(
            children: [
              for (final bill in visible) ...[
                _ListCardRow(
                  icon: Icons.credit_card_rounded,
                  title: bill.name,
                  subtitle: _billDueLabel(bill.nextDueDate),
                  amount: formatCurrency(bill.amount),
                ),
                if (bill != visible.last) const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }
}

class _GoalProgressSection extends ConsumerWidget {
  const _GoalProgressSection({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsStreamProvider).valueOrNull ?? const <Goal>[];
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final insights =
        ref.watch(goalInsightsProvider).valueOrNull ??
        const <String, GoalInsight>{};

    final ordered = <Goal>[];
    final seenGoalKeys = <String>{};
    for (final goal in goals) {
      final key = [
        goal.name.trim().toLowerCase(),
        goal.targetAmount.toStringAsFixed(2),
        DateTime(
          goal.targetDate.year,
          goal.targetDate.month,
          goal.targetDate.day,
        ).toIso8601String(),
      ].join('|');
      if (seenGoalKeys.add(key)) {
        ordered.add(goal);
      }
    }
    if (settings?.primaryGoalId != null) {
      ordered.sort((a, b) {
        final aRank = a.id == settings!.primaryGoalId ? 0 : 1;
        final bRank = b.id == settings.primaryGoalId ? 0 : 1;
        return aRank.compareTo(bRank);
      });
    }
    final visible = ordered.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Goal progress',
          actionLabel: 'See goals',
          onTap: onViewAll,
        ),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          const _EmptyCard(message: 'No goals yet. Add one to track progress.')
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                for (final goal in visible) ...[
                  _GoalProgressRow(goal: goal, insight: insights[goal.id]),
                  if (goal != visible.last) const SizedBox(height: 16),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  const _GoalProgressRow({required this.goal, required this.insight});

  final Goal goal;
  final GoalInsight? insight;

  @override
  Widget build(BuildContext context) {
    final progress = insight?.progress ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.name,
                style: const TextStyle(
                  color: _HomePalette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: _HomePalette.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: _HomePalette.progressTrack,
            valueColor: const AlwaysStoppedAnimation(_HomePalette.progressFill),
          ),
        ),
      ],
    );
  }
}

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions =
        ref.watch(recentTransactionsProvider).valueOrNull ??
        const <Transaction>[];
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final categoryMap = {
      for (final category in categories) category.id: category,
    };
    final visible = transactions.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Recent activity',
          actionLabel: 'View all',
          onTap: onViewAll,
        ),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          const _EmptyCard(message: 'No activity yet.')
        else
          Column(
            children: [
              for (final txn in visible) ...[
                _ActivityCard(
                  transaction: txn,
                  category: categoryMap[txn.categoryId],
                ),
                if (txn != visible.last) const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _HomePalette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: _HomePalette.textSecondary,
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _ListCardRow extends StatelessWidget {
  const _ListCardRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _HomePalette.iconCircle,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: _HomePalette.iconAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _HomePalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _HomePalette.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: const TextStyle(
              color: _HomePalette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.transaction, required this.category});

  final Transaction transaction;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';
    final amountColor =
        isIncome ? _HomePalette.positive : _HomePalette.textPrimary;
    final icon = switch (transaction.type) {
      'income' => Icons.payments_outlined,
      'adjustment' => Icons.sync_alt_rounded,
      _ => Icons.receipt_long_outlined,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _HomePalette.iconCircle,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: _HomePalette.iconAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _transactionTitle(transaction, category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomePalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _activitySubtitle(transaction),
                  style: const TextStyle(
                    color: _HomePalette.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isExpense ? '-' : '+'}${formatCurrency(transaction.amount.abs())}',
            style: TextStyle(
              color: amountColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(color: _HomePalette.textSecondary, fontSize: 14),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: _HomePalette.textPrimary, size: 22),
        ),
      ),
    );
  }
}

List<double> _weeklySpendBars(List<Transaction> transactions) {
  final start = _startOfWeek(DateTime.now());
  final values = List<double>.filled(7, 0);
  for (final txn in transactions) {
    if (txn.type != 'expense') continue;
    final day = DateTime(txn.date.year, txn.date.month, txn.date.day);
    final offset = day.difference(start).inDays;
    if (offset >= 0 && offset < 7) {
      values[offset] += txn.amount;
    }
  }

  final maxValue = values.fold<double>(0, math.max);
  if (maxValue <= 0) {
    return List<double>.filled(7, 18);
  }
  return values
      .map((value) => 16 + ((value / maxValue) * 62))
      .toList(growable: false);
}

DateTime _startOfWeek(DateTime now) {
  final day = DateTime(now.year, now.month, now.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

DateTime _startOfDay(DateTime now) => DateTime(now.year, now.month, now.day);

String _dailyPacingLabel({
  required double? remainingToday,
  required double? todaySpend,
  required double? dailyAllowance,
}) {
  if (remainingToday == null || dailyAllowance == null) {
    return 'Daily budget will appear once guidance is ready';
  }
  if (remainingToday < 0) {
    return 'You are ${formatCurrency(remainingToday.abs())} over today';
  }
  if (todaySpend == null || todaySpend <= 0) {
    return '${formatCurrency(remainingToday)} available for today';
  }
  final pct =
      dailyAllowance > 0
          ? (remainingToday / dailyAllowance * 100).clamp(0, 100).round()
          : 0;
  return '$pct% of today\'s budget still available';
}

String _trendText(double? trend) {
  if (trend == null) return 'No comparison';
  final rounded = trend.abs().round();
  if (trend <= 0) return 'Down $rounded%';
  return 'Up $rounded%';
}

String _badgeLabel(LocalBadgeId badge) {
  return switch (badge) {
    LocalBadgeId.firstExpenseAdded => 'First expense',
    LocalBadgeId.firstGoalCreated => 'First goal',
    LocalBadgeId.sevenDayTrackingStreak => '7-day streak',
    LocalBadgeId.underBudgetToday => 'Under budget',
    LocalBadgeId.savedThisWeek => 'Saved this week',
    LocalBadgeId.billPaidOnTime => 'Bill paid',
  };
}

IconData _badgeIcon(LocalBadgeId badge) {
  return switch (badge) {
    LocalBadgeId.firstExpenseAdded => Icons.receipt_long_outlined,
    LocalBadgeId.firstGoalCreated => Icons.flag_outlined,
    LocalBadgeId.sevenDayTrackingStreak => Icons.local_fire_department_outlined,
    LocalBadgeId.underBudgetToday => Icons.check_circle_outline_rounded,
    LocalBadgeId.savedThisWeek => Icons.savings_outlined,
    LocalBadgeId.billPaidOnTime => Icons.event_available_outlined,
  };
}

String _billDueLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(date.year, date.month, date.day);
  final diff = dueDay.difference(today).inDays;
  if (diff == 0) return 'Due today';
  if (diff == 1) return 'Due tomorrow';
  if (diff > 1 && diff <= 7) return 'In $diff days';
  return DateFormat.MMMd().format(date);
}

String _transactionTitle(Transaction transaction, Category? category) {
  final note = transaction.note?.trim();
  if (note != null && note.isNotEmpty) return note;
  if (category != null) return category.name;
  return switch (transaction.type) {
    'expense' => 'Expense',
    'income' =>
      transaction.source?.trim().isNotEmpty == true
          ? transaction.source!
          : 'Income',
    'adjustment' => 'Adjustment',
    _ => 'Transaction',
  };
}

String _activitySubtitle(Transaction transaction) {
  final date = DateTime(
    transaction.date.year,
    transaction.date.month,
    transaction.date.day,
  );
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(date).inDays;

  if (diff == 0) {
    return 'Today, ${DateFormat.jm().format(transaction.date)}';
  }
  if (diff == 1) return 'Yesterday';
  return DateFormat.MMMd().format(transaction.date);
}

abstract final class _HomePalette {
  static const background = Color(0xFFF5F7FB);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const summaryCard = Color(0xFF132440);
  static const summaryMuted = Color(0x8CFFFFFF);
  static const positive = Color(0xFF3B9797);
  static const mintCard = Color(0xFFF0FDFA);
  static const mintAccent = Color(0xFF0F766E);
  static const incomeCard = Color(0xFFFFF7ED);
  static const incomeAccent = Color(0xFFC26A38);
  static const iconCircle = Color(0xFFF1F5F9);
  static const iconAccent = Color(0xFF475569);
  static const chartBar = Color(0xFF3B9797);
  static const progressTrack = Color(0xFFE2E8F0);
  static const progressFill = Color(0xFF3B9797);
  static const line = Color(0xFFE7ECF4);
  static const alert = Color(0xFFD0746B);
}
