import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/analytics/leko_analytics.dart';
import '../../core/providers/analytics_providers.dart';
import '../../core/providers/allowance_providers.dart';
import '../../core/providers/badge_providers.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/bills_providers.dart';
import '../../core/providers/goals_providers.dart';
import '../../core/providers/integration_providers.dart';
import '../../core/providers/ledger_providers.dart';
import '../../core/providers/profile_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/leko_mark.dart';
import '../../data/db/leko_database.dart';
import '../../domain/integrations/product_foundations.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/allowance_engine.dart';
import '../goals/goals_screen.dart' show GoalInsight, goalInsightsProvider;
import 'widgets/savings_pace_card.dart';

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
            const _HomeAnalyticsPing(),
            _Header(onNotifications: () => context.push('/closeout')),
            const SizedBox(height: 22),
            const _SafeToSpendHero(),
            const SizedBox(height: 14),
            _AttentionStrip(
              onReview: () => context.push('/imports'),
              onBills: () => context.push('/bills'),
              onAskLeaf: () => context.go('/leaf'),
            ),
            const SizedBox(height: 14),
            _QuickActionsRow(
              onAddExpense: () {
                ref
                    .read(lekoAnalyticsProvider)
                    .track(
                      LekoAnalyticsEvent.quickActionStarted,
                      properties: const {'action': 'add_expense'},
                    );
                context.push('/add-expense');
              },
              onAddIncome: () {
                ref
                    .read(lekoAnalyticsProvider)
                    .track(
                      LekoAnalyticsEvent.quickActionStarted,
                      properties: const {'action': 'add_income'},
                    );
                context.push('/add-income');
              },
              onAddGoal: () {
                ref
                    .read(lekoAnalyticsProvider)
                    .track(
                      LekoAnalyticsEvent.quickActionStarted,
                      properties: const {'action': 'add_goal'},
                    );
                context.go('/goals?add=1');
              },
            ),
            const SizedBox(height: 18),
            _UpcomingBillsSection(onViewAll: () => context.push('/bills')),
            const SizedBox(height: 18),
            const SavingsPaceCard(),
            const SizedBox(height: 18),
            const _WeeklySpendingCard(),
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

class _HomeAnalyticsPing extends ConsumerStatefulWidget {
  const _HomeAnalyticsPing();

  @override
  ConsumerState<_HomeAnalyticsPing> createState() => _HomeAnalyticsPingState();
}

class _HomeAnalyticsPingState extends ConsumerState<_HomeAnalyticsPing> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref.read(lekoAnalyticsProvider).track(LekoAnalyticsEvent.homeViewed),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
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
                '${_greetingPrefix()}, $greetingName',
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

class _TodayMoneySnapshot {
  const _TodayMoneySnapshot({
    required this.mode,
    required this.balance,
    required this.dailyAllowance,
    required this.todaySpend,
    required this.remainingToday,
    required this.projectedIncome,
    required this.projectedBills,
    required this.spendablePool,
    required this.horizonDays,
    required this.horizonLabel,
    required this.goalName,
    required this.goalTarget,
    required this.isReady,
  });

  final AllowanceMode mode;
  final double? balance;
  final double? dailyAllowance;
  final double? todaySpend;
  final double? remainingToday;
  final double? projectedIncome;
  final double? projectedBills;
  final double? spendablePool;
  final int? horizonDays;
  final String horizonLabel;
  final String? goalName;
  final double? goalTarget;
  final bool isReady;

  bool get isOver => remainingToday != null && remainingToday! < 0;

  static _TodayMoneySnapshot from({
    required AllowanceMode mode,
    required PaycheckAllowanceResult? paycheck,
    required GoalAllowanceResult? goal,
  }) {
    if (mode == AllowanceMode.goal && goal != null) {
      return _TodayMoneySnapshot(
        mode: mode,
        balance: goal.balance,
        dailyAllowance: goal.dailyAllowance,
        todaySpend: goal.todaySpend,
        remainingToday: goal.remainingToday,
        projectedIncome: goal.projectedIncome,
        projectedBills: goal.projectedBills,
        spendablePool: goal.spendablePool,
        horizonDays: goal.daysToGoal,
        horizonLabel: 'days to ${goal.goal.name}',
        goalName: goal.goal.name,
        goalTarget: goal.goal.targetAmount,
        isReady: true,
      );
    }
    if (mode == AllowanceMode.paycheck && paycheck != null) {
      return _TodayMoneySnapshot(
        mode: mode,
        balance: paycheck.balance,
        dailyAllowance: paycheck.dailyAllowance,
        todaySpend: paycheck.todaySpend,
        remainingToday: paycheck.remainingToday,
        projectedIncome: paycheck.projectedIncome,
        projectedBills: paycheck.projectedBills,
        spendablePool: paycheck.spendablePool,
        horizonDays: paycheck.daysLeft,
        horizonLabel: 'days left in cycle',
        goalName: null,
        goalTarget: null,
        isReady: true,
      );
    }
    return _TodayMoneySnapshot(
      mode: mode,
      balance: null,
      dailyAllowance: null,
      todaySpend: null,
      remainingToday: null,
      projectedIncome: null,
      projectedBills: null,
      spendablePool: null,
      horizonDays: null,
      horizonLabel:
          mode == AllowanceMode.goal
              ? 'goal plan not ready'
              : 'cycle not ready',
      goalName: null,
      goalTarget: null,
      isReady: false,
    );
  }
}

class _SafeToSpendHero extends ConsumerWidget {
  const _SafeToSpendHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(effectiveAllowanceModeProvider);
    final paycheck = ref.watch(paycheckAllowanceProvider).valueOrNull;
    final goal = ref.watch(goalAllowanceProvider).valueOrNull;
    final upcomingBills =
        ref.watch(upcomingBillsProvider).valueOrNull ?? const [];
    final snapshot = _TodayMoneySnapshot.from(
      mode: mode,
      paycheck: paycheck,
      goal: goal,
    );

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
                  snapshot.isOver ? 'OVER TODAY' : 'SAFE TO SPEND TODAY',
                  style: const TextStyle(
                    color: _HomePalette.summaryMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
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
                child: const Center(
                  child: LekoMark(size: 24, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            snapshot.remainingToday != null
                ? formatCurrency(snapshot.remainingToday!.abs())
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
                    remainingToday: snapshot.remainingToday,
                    todaySpend: snapshot.todaySpend,
                    dailyAllowance: snapshot.dailyAllowance,
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
          _HeroWhyButton(
            onTap: () {
              ref
                  .read(lekoAnalyticsProvider)
                  .track(
                    LekoAnalyticsEvent.safeToSpendExplained,
                    properties: {'ready': snapshot.isReady},
                  );
              _showAllowanceBreakdown(context, snapshot);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryMiniPanel(
                  title: 'Daily budget',
                  value:
                      snapshot.dailyAllowance == null
                          ? 'Not ready'
                          : formatCurrency(snapshot.dailyAllowance!),
                  subtitle:
                      snapshot.todaySpend == null
                          ? 'Today\'s spend will appear here'
                          : '${formatCurrency(snapshot.todaySpend!)} spent today',
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

class _HeroWhyButton extends StatelessWidget {
  const _HeroWhyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'See how Leko calculated this',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: _HomePalette.summaryMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showAllowanceBreakdown(
  BuildContext context,
  _TodayMoneySnapshot snapshot,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AllowanceBreakdownSheet(snapshot: snapshot),
  );
}

class _AllowanceBreakdownSheet extends StatelessWidget {
  const _AllowanceBreakdownSheet({required this.snapshot});

  final _TodayMoneySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x240F172A),
              blurRadius: 28,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _HomePalette.iconCircle,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.calculate_outlined,
                    color: _HomePalette.iconAccent,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why this number?',
                        style: TextStyle(
                          color: _HomePalette.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'The live inputs behind safe-to-spend.',
                        style: TextStyle(
                          color: _HomePalette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _BreakdownRow(
              label: 'Current balance',
              value: _moneyOrPending(snapshot.balance),
            ),
            _BreakdownRow(
              label: 'Projected income',
              value: _moneyOrPending(snapshot.projectedIncome),
              positive: true,
            ),
            _BreakdownRow(
              label: 'Upcoming bills',
              value: _moneyOrPending(snapshot.projectedBills),
              negative: true,
            ),
            if (snapshot.goalTarget != null)
              _BreakdownRow(
                label: 'Goal reserve',
                value: _moneyOrPending(snapshot.goalTarget),
                negative: true,
              ),
            const Divider(height: 22, color: _HomePalette.line),
            _BreakdownRow(
              label: 'Spendable pool',
              value: _moneyOrPending(snapshot.spendablePool),
              emphasized: true,
            ),
            _BreakdownRow(
              label: snapshot.horizonLabel,
              value:
                  snapshot.horizonDays == null
                      ? 'Pending'
                      : '${snapshot.horizonDays} day${snapshot.horizonDays == 1 ? '' : 's'}',
            ),
            _BreakdownRow(
              label: 'Daily budget',
              value: _moneyOrPending(snapshot.dailyAllowance),
              emphasized: true,
            ),
            _BreakdownRow(
              label: 'Spent today',
              value: _moneyOrPending(snapshot.todaySpend),
              negative: true,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _HomePalette.mintCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _HomePalette.line),
              ),
              child: Text(
                snapshot.isReady
                    ? 'Safe-to-spend is daily budget minus what you have already spent today.'
                    : 'Add balance, income, bills, or a goal so Leko can calculate this with confidence.',
                style: const TextStyle(
                  color: _HomePalette.textPrimary,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.positive = false,
    this.negative = false,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool positive;
  final bool negative;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final valueColor =
        positive
            ? _HomePalette.positive
            : negative
            ? _HomePalette.alert
            : _HomePalette.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color:
                    emphasized
                        ? _HomePalette.textPrimary
                        : _HomePalette.textSecondary,
                fontSize: 14,
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionStrip extends ConsumerWidget {
  const _AttentionStrip({
    required this.onReview,
    required this.onBills,
    required this.onAskLeaf,
  });

  final VoidCallback onReview;
  final VoidCallback onBills;
  final VoidCallback onAskLeaf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(transactionReviewControllerProvider);
    final pendingCount = reviewState.pending.length;
    if (pendingCount > 0) {
      return _AttentionCard(
        icon: Icons.fact_check_outlined,
        title:
            '$pendingCount transaction${pendingCount == 1 ? '' : 's'} need review',
        subtitle: 'Approve imports before they change your ledger.',
        actionLabel: 'Review',
        onTap: onReview,
      );
    }

    final mode = ref.watch(effectiveAllowanceModeProvider);
    final paycheck = ref.watch(paycheckAllowanceProvider).valueOrNull;
    final goal = ref.watch(goalAllowanceProvider).valueOrNull;
    final snapshot = _TodayMoneySnapshot.from(
      mode: mode,
      paycheck: paycheck,
      goal: goal,
    );
    if (snapshot.isOver) {
      return _AttentionCard(
        icon: Icons.trending_up_rounded,
        title: 'Over pace today',
        subtitle: _dailyPacingLabel(
          remainingToday: snapshot.remainingToday,
          todaySpend: snapshot.todaySpend,
          dailyAllowance: snapshot.dailyAllowance,
        ),
        actionLabel: 'Ask Leaf',
        onTap: onAskLeaf,
        tone: _AttentionTone.alert,
      );
    }

    final bills =
        ref.watch(upcomingBillsProvider).valueOrNull ?? const <Bill>[];
    final dueBill = _firstDueToday(bills);
    if (dueBill != null) {
      return _AttentionCard(
        icon: Icons.event_available_outlined,
        title: '${dueBill.name} is due today',
        subtitle: '${formatCurrency(dueBill.amount)} scheduled bill.',
        actionLabel: 'Bills',
        onTap: onBills,
      );
    }

    return const SizedBox.shrink();
  }
}

enum _AttentionTone { neutral, alert }

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.tone = _AttentionTone.neutral,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final _AttentionTone tone;

  @override
  Widget build(BuildContext context) {
    final isAlert = tone == _AttentionTone.alert;
    final accent = isAlert ? _HomePalette.alert : _HomePalette.mintAccent;
    final background =
        isAlert ? const Color(0xFFFFF7F5) : _HomePalette.mintCard;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _HomePalette.line),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomePalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomePalette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                actionLabel,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
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
            label: 'Add Expense',
            icon: Icons.add_rounded,
            background: _HomePalette.summaryCard,
            textColor: Colors.white,
            iconBackground: Colors.white.withValues(alpha: 0.12),
            iconAccent: Colors.white,
            borderColor: Colors.transparent,
            onTap: onAddExpense,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            label: 'Add Income',
            icon: Icons.payments_outlined,
            background: _HomePalette.incomeCard,
            textColor: _HomePalette.textPrimary,
            iconBackground: Colors.white.withValues(alpha: 0.58),
            iconAccent: _HomePalette.incomeAccent,
            borderColor: const Color(0xFFDDE8E0),
            onTap: onAddIncome,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            label: 'Add Goal',
            icon: Icons.gps_fixed_rounded,
            background: _HomePalette.mintCard,
            textColor: _HomePalette.textPrimary,
            iconBackground: Colors.white.withValues(alpha: 0.58),
            iconAccent: _HomePalette.mintAccent,
            borderColor: const Color(0xFFD9EAE3),
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
    this.textColor = _HomePalette.textPrimary,
    this.iconBackground = _HomePalette.iconCircle,
    this.iconAccent = _HomePalette.iconCircle,
    this.borderColor = _HomePalette.line,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color textColor;
  final Color iconBackground;
  final Color iconAccent;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 94,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: iconAccent, size: 18),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.north_east_rounded,
                    color: textColor.withValues(alpha: 0.58),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
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
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < bars.length; i++) ...[
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 10,
                        height: math.max(bars[i] * 0.72, 4),
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
          const SizedBox(height: 8),
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

String _greetingPrefix() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

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

String _moneyOrPending(double? value) {
  if (value == null) return 'Pending';
  return formatCurrency(value);
}

Bill? _firstDueToday(List<Bill> bills) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueToday =
      bills.where((bill) {
          final due = DateTime(
            bill.nextDueDate.year,
            bill.nextDueDate.month,
            bill.nextDueDate.day,
          );
          return due == today;
        }).toList()
        ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  return dueToday.isEmpty ? null : dueToday.first;
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
