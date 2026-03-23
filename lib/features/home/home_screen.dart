import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/allowance_providers.dart';
import '../../core/providers/closeout_providers.dart';
import '../../core/providers/goals_providers.dart';
import '../../core/providers/ledger_providers.dart';
import '../../core/providers/plant_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/db/leko_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/allowance_engine.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(plantUpdateProvider);

    return Scaffold(
      backgroundColor: _HomePalette.background,
      body: Stack(
        children: [
          const _AtmosphericBackground(),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                _TopBar(
                  onSettings: () => context.go('/settings'),
                  onStreakTap: () => context.push('/closeout'),
                ),
                const SizedBox(height: 26),
                const _BalanceSection(),
                const SizedBox(height: 22),
                const _DailyGuidanceCard(),
                const SizedBox(height: 18),
                _QuickActionsPanel(
                  onAddExpense: () => context.push('/add-expense'),
                  onAddIncome: () => context.push('/add-income'),
                  onMarkBillPaid: () => context.push('/bills'),
                  onSplits: () => context.push('/splits'),
                ),
                const SizedBox(height: 18),
                _GoalSpotlightCard(onOpenGoals: () => context.go('/goals')),
                const SizedBox(height: 24),
                const _RecentTransactionsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AtmosphericBackground extends StatelessWidget {
  const _AtmosphericBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071214),
            Color(0xFF0B1A1D),
            Color(0xFF101B1C),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: _GlowOrb(
              size: 220,
              color: _HomePalette.teal.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            top: 140,
            right: -60,
            child: _GlowOrb(
              size: 180,
              color: const Color(0xFF5CC3AE).withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: 160,
            left: 40,
            child: _GlowOrb(
              size: 140,
              color: const Color(0xFFF1C79C).withValues(alpha: 0.06),
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
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.onSettings, required this.onStreakTap});

  final VoidCallback onSettings;
  final VoidCallback onStreakTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(effectiveAllowanceModeProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StreakBadge(onTap: onStreakTap),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniStatusChip(
              icon: mode == AllowanceMode.paycheck
                  ? Icons.event_repeat_rounded
                  : Icons.flag_rounded,
              label: mode == AllowanceMode.paycheck ? 'Cycle' : 'Goal',
            ),
            const SizedBox(width: 10),
            _IconChromeButton(
              icon: Icons.tune_rounded,
              onTap: onSettings,
            ),
          ],
        ),
      ],
    );
  }
}

class _StreakBadge extends ConsumerWidget {
  const _StreakBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _HomePalette.surfaceRaised.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _HomePalette.outline.withValues(alpha: 0.9),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: _HomePalette.highlight,
              ),
              const SizedBox(width: 8),
              streakAsync.when(
                data: (s) => Text(
                  '${s.currentStreak}',
                  style: const TextStyle(
                    color: _HomePalette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _HomePalette.highlight,
                  ),
                ),
                error: (_, __) => const Text(
                  '--',
                  style: TextStyle(
                    color: _HomePalette.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatusChip extends StatelessWidget {
  const _MiniStatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _HomePalette.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomePalette.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _HomePalette.tealSoft),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _HomePalette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconChromeButton extends StatelessWidget {
  const _IconChromeButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _HomePalette.surfaceRaised.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _HomePalette.outline),
          ),
          child: Icon(
            icon,
            size: 18,
            color: _HomePalette.textMuted,
          ),
        ),
      ),
    );
  }
}

class _BalanceSection extends ConsumerStatefulWidget {
  const _BalanceSection();

  @override
  ConsumerState<_BalanceSection> createState() => _BalanceSectionState();
}

class _BalanceSectionState extends ConsumerState<_BalanceSection> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(balanceStreamProvider);
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final mode = ref.watch(effectiveAllowanceModeProvider);
    final paycheck = ref.watch(paycheckAllowanceProvider).valueOrNull;
    final goal = ref.watch(goalAllowanceProvider).valueOrNull;

    final supportText = switch (mode) {
      AllowanceMode.paycheck when paycheck != null =>
        'Cycle ${_rangeLabel(paycheck.cycleWindow.start, paycheck.cycleWindow.end)}',
      AllowanceMode.goal when goal != null =>
        'Guiding toward ${DateFormat.MMMd().format(goal.goal.targetDate)}',
      _ => 'Updated today',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Current balance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _HomePalette.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                ),
              ),
              const Spacer(),
              _CurrencyPill(code: (settings?.baseCurrency.name ?? 'cad').toUpperCase()),
              const SizedBox(width: 10),
              _VisibilityPill(
                hidden: _hidden,
                onTap: () => setState(() => _hidden = !_hidden),
              ),
            ],
          ),
          const SizedBox(height: 12),
          balanceAsync.when(
            data: (balance) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _hidden ? '••••••' : formatCurrency(balance),
                key: ValueKey('${_hidden}_$balance'),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: _HomePalette.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 48,
                  height: 1.0,
                  letterSpacing: -2.2,
                ),
              ),
            ),
            loading: () => Container(
              width: 210,
              height: 42,
              decoration: BoxDecoration(
                color: _HomePalette.surfaceRaised,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            error: (_, __) => const Text(
              'Unable to load balance',
              style: TextStyle(
                color: _HomePalette.alert,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            supportText,
            style: const TextStyle(
              color: _HomePalette.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _HomePalette.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomePalette.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _HomePalette.tealSoft,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            code,
            style: const TextStyle(
              color: _HomePalette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityPill extends StatelessWidget {
  const _VisibilityPill({required this.hidden, required this.onTap});

  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _HomePalette.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _HomePalette.outline),
          ),
          child: Icon(
            hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: _HomePalette.textMuted,
          ),
        ),
      ),
    );
  }
}

class _DailyGuidanceCard extends ConsumerWidget {
  const _DailyGuidanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(effectiveAllowanceModeProvider);

    return switch (mode) {
      AllowanceMode.paycheck => _PaycheckGuidanceCard(
          resultAsync: ref.watch(paycheckAllowanceProvider),
        ),
      AllowanceMode.goal => _GoalGuidanceCard(
          resultAsync: ref.watch(goalAllowanceProvider),
        ),
    };
  }
}

class _PaycheckGuidanceCard extends ConsumerWidget {
  const _PaycheckGuidanceCard({required this.resultAsync});

  final AsyncValue<PaycheckAllowanceResult?> resultAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return resultAsync.when(
      data: (result) {
        if (result == null) {
          return const _GuidanceShell();
        }

        final tone =
            result.behindAmount > 0
                ? 'Ease up a little today to stay in rhythm.'
                : result.bankedAllowance > 0
                ? 'You have a little room from earlier disciplined days.'
                : 'A calm pace today keeps this cycle feeling light.';

        return _GuidanceCardFrame(
          title: 'You can spend today',
          subtitle: tone,
          amount: formatCurrency(result.allowanceToday),
          footer: result.behindAmount > 0
              ? _HeroNotice(
                  icon: Icons.warning_amber_rounded,
                  text: 'Behind by ${formatCurrency(result.behindAmount)} this cycle',
                  color: _HomePalette.alert,
                )
              : _HeroNotice(
                  icon: Icons.auto_awesome_rounded,
                  text: 'Steady pace to next paycheck',
                  color: _HomePalette.tealSoft,
                ),
          stats: [
            _HeroStat(
              label: 'Banked',
              value: formatCurrency(result.bankedAllowance),
              accent:
                  result.bankedAllowance >= 0
                      ? _HomePalette.tealSoft
                      : _HomePalette.alert,
            ),
            _HeroStat(
              label: 'Days left',
              value: '${result.daysLeft}',
              accent: _HomePalette.textPrimary,
            ),
            _HeroStat(
              label: 'Cycle',
              value: _rangeLabel(
                result.cycleWindow.start,
                result.cycleWindow.end,
              ),
              accent: _HomePalette.textPrimary,
              alignEnd: true,
            ),
          ],
        );
      },
      loading: () => const _GuidanceShell(),
      error: (_, __) => const _GuidanceShell(
        message: 'We could not calculate today\'s pace yet.',
      ),
    );
  }
}

class _GoalGuidanceCard extends ConsumerWidget {
  const _GoalGuidanceCard({required this.resultAsync});

  final AsyncValue<GoalAllowanceResult?> resultAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return resultAsync.when(
      data: (result) {
        if (result == null) {
          return const _GuidanceShell(
            message: 'Set a primary goal to shape daily guidance.',
          );
        }

        final tone =
            result.feasibility.isFeasible
                ? 'Today\'s number protects your goal without feeling harsh.'
                : 'A gentler pace now will help keep your goal believable.';

        return _GuidanceCardFrame(
          title: 'You can spend today',
          subtitle: tone,
          amount: formatCurrency(result.allowanceToday),
          footer: result.feasibility.isFeasible
              ? _HeroNotice(
                  icon: Icons.flag_circle_rounded,
                  text: 'Focused on ${result.goal.name}',
                  color: _HomePalette.goldSoft,
                )
              : _HeroNotice(
                  icon: Icons.trending_up_rounded,
                  text: 'Short by ${formatCurrency(result.feasibility.deficit)}',
                  color: _HomePalette.alert,
                ),
          stats: [
            _HeroStat(
              label: 'Target',
              value: formatCurrency(result.goal.targetAmount),
              accent: _HomePalette.textPrimary,
            ),
            _HeroStat(
              label: 'By',
              value: DateFormat.MMMd().format(result.goal.targetDate),
              accent: _HomePalette.textPrimary,
            ),
            _HeroStat(
              label: 'Banked',
              value: formatCurrency(result.bankedAllowance),
              accent:
                  result.bankedAllowance >= 0
                      ? _HomePalette.tealSoft
                      : _HomePalette.alert,
              alignEnd: true,
            ),
          ],
        );
      },
      loading: () => const _GuidanceShell(),
      error: (_, __) => const _GuidanceShell(
        message: 'We could not calculate goal guidance yet.',
      ),
    );
  }
}

class _GuidanceCardFrame extends ConsumerWidget {
  const _GuidanceCardFrame({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.stats,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final String amount;
  final List<_HeroStat> stats;
  final Widget footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123036), Color(0xFF0D1E22)],
        ),
        border: Border.all(color: _HomePalette.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: _HomePalette.teal.withValues(alpha: 0.08),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _HomePalette.textMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _HomePalette.textSoft,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const _AllowanceModePill(),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            amount,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: _HomePalette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 54,
              letterSpacing: -2.8,
              height: 0.96,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: Row(
              children: [
                for (var i = 0; i < stats.length; i++) ...[
                  Expanded(child: stats[i]),
                  if (i != stats.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          footer,
        ],
      ),
    );
  }
}

class _GuidanceShell extends StatelessWidget {
  const _GuidanceShell({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: _HomePalette.surface,
        border: Border.all(color: _HomePalette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'You can spend today',
                style: TextStyle(
                  color: _HomePalette.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _AllowanceModePill(),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: 190,
            height: 54,
            decoration: BoxDecoration(
              color: _HomePalette.surfaceRaised,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 18),
            Text(
              message!,
              style: const TextStyle(
                color: _HomePalette.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AllowanceModePill extends ConsumerWidget {
  const _AllowanceModePill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(effectiveAllowanceModeProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final next =
              mode == AllowanceMode.paycheck
                  ? AllowanceMode.goal
                  : AllowanceMode.paycheck;
          ref.read(allowanceModeOverrideProvider.notifier).state = next;
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mode == AllowanceMode.paycheck ? 'To paycheck' : 'To goal',
                style: const TextStyle(
                  color: _HomePalette.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.swap_horiz_rounded,
                size: 14,
                color: _HomePalette.tealSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.accent,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color accent;
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
            color: _HomePalette.textMuted,
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
          style: TextStyle(
            color: accent,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeroNotice extends StatelessWidget {
  const _HeroNotice({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onMarkBillPaid,
    required this.onSplits,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onMarkBillPaid;
  final VoidCallback onSplits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _HomePalette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _HomePalette.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.remove_rounded,
              label: 'Expense',
              accent: _HomePalette.alert,
              onTap: onAddExpense,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.add_rounded,
              label: 'Income',
              accent: _HomePalette.tealSoft,
              onTap: onAddIncome,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.receipt_long_rounded,
              label: 'Pay bill',
              accent: _HomePalette.goldSoft,
              onTap: onMarkBillPaid,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.call_split_rounded,
              label: 'Split',
              accent: _HomePalette.teal,
              onTap: onSplits,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: _HomePalette.surfaceRaised,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _HomePalette.textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalSpotlightCard extends ConsumerWidget {
  const _GoalSpotlightCard({required this.onOpenGoals});

  final VoidCallback onOpenGoals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStreamProvider).valueOrNull;
    final goals = ref.watch(goalsStreamProvider).valueOrNull ?? const <Goal>[];

    Goal? goal;
    final primaryGoalId = settings?.primaryGoalId;
    if (primaryGoalId != null) {
      for (final item in goals) {
        if (item.id == primaryGoalId) {
          goal = item;
          break;
        }
      }
    }
    goal ??= goals.isNotEmpty ? goals.first : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _HomePalette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _HomePalette.outline),
      ),
      child: goal == null
          ? _EmptyGoalCard(onOpenGoals: onOpenGoals)
          : _GoalCardContent(goal: goal, isPrimary: goal.id == primaryGoalId),
    );
  }
}

class _EmptyGoalCard extends StatelessWidget {
  const _EmptyGoalCard({required this.onOpenGoals});

  final VoidCallback onOpenGoals;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Keep a goal in view',
                style: TextStyle(
                  color: _HomePalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Give today\'s budget something quiet and meaningful to protect.',
                style: TextStyle(
                  color: _HomePalette.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: onOpenGoals,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  foregroundColor: _HomePalette.tealSoft,
                ),
                child: const Text(
                  'Open Goals',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: _HomePalette.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.flag_rounded,
            color: _HomePalette.tealSoft,
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _GoalCardContent extends StatelessWidget {
  const _GoalCardContent({required this.goal, required this.isPrimary});

  final Goal goal;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _HomePalette.goldSoft.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.flag_circle_rounded,
                color: _HomePalette.goldSoft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPrimary ? 'Primary goal' : 'Goal in focus',
                    style: const TextStyle(
                      color: _HomePalette.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    goal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _HomePalette.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: _HomePalette.textMuted,
              size: 18,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Daily guidance keeps this goal on the horizon without making the screen feel heavy.',
          style: TextStyle(
            color: _HomePalette.textSoft,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SecondaryStatTile(
                label: 'Target',
                value: formatCurrency(goal.targetAmount),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SecondaryStatTile(
                label: 'By',
                value: DateFormat.yMMMd().format(goal.targetDate),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryStatTile extends StatelessWidget {
  const _SecondaryStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _HomePalette.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: _HomePalette.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.75,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _HomePalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsSection extends ConsumerWidget {
  const _RecentTransactionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(recentTransactionsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final categoryMap = {for (final category in categories) category.id: category};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent activity',
                style: TextStyle(
                  color: _HomePalette.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/transactions'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: _HomePalette.tealSoft,
              ),
              child: const Text(
                'View all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _HomePalette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _HomePalette.outline),
          ),
          child: transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'No transactions yet.',
                      style: TextStyle(
                        color: _HomePalette.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }

              final recent = transactions.take(5).toList();
              return Column(
                children: [
                  for (var i = 0; i < recent.length; i++) ...[
                    _RecentTransactionRow(
                      transaction: recent[i],
                      category: categoryMap[recent[i].categoryId],
                    ),
                    if (i != recent.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.white.withValues(alpha: 0.04),
                        indent: 64,
                      ),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(
                  color: _HomePalette.tealSoft,
                ),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Unable to load recent transactions.',
                  style: TextStyle(color: _HomePalette.alert),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentTransactionRow extends StatelessWidget {
  const _RecentTransactionRow({
    required this.transaction,
    required this.category,
  });

  final Transaction transaction;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';
    final amountColor =
        isExpense
            ? _HomePalette.alertSoft
            : isIncome
            ? _HomePalette.tealSoft
            : _HomePalette.goldSoft;
    final iconColor = _categoryAccent(category?.defaultLabel, transaction.type);
    final amount =
        '${isExpense ? '-' : '+'}${formatCurrency(transaction.amount.abs())}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _transactionIcon(transaction.type),
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
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
                  _transactionSubtitle(transaction, category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomePalette.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _transactionTitle(Transaction transaction, Category? category) {
  final note = transaction.note?.trim();
  if (note != null && note.isNotEmpty) return note;
  if (category != null) return category.name;
  return switch (transaction.type) {
    'expense' => 'Expense',
    'income' => transaction.source?.trim().isNotEmpty == true
        ? transaction.source!
        : 'Income',
    'adjustment' => 'Adjustment',
    _ => 'Transaction',
  };
}

String _transactionSubtitle(Transaction transaction, Category? category) {
  final date = _relativeDateLabel(transaction.date);
  final categoryName = category?.name;
  if (categoryName != null && categoryName.isNotEmpty) {
    return '$categoryName • $date';
  }
  return date;
}

String _relativeDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return DateFormat.MMMd().format(date);
}

String _rangeLabel(DateTime start, DateTime end) {
  final fmt = DateFormat.MMMd();
  return '${fmt.format(start)} - ${fmt.format(end)}';
}

IconData _transactionIcon(String type) {
  return switch (type) {
    'expense' => Icons.arrow_upward_rounded,
    'income' => Icons.arrow_downward_rounded,
    'adjustment' => Icons.sync_alt_rounded,
    _ => Icons.circle_rounded,
  };
}

Color _categoryAccent(String? defaultLabel, String type) {
  if (type == 'income') return _HomePalette.tealSoft;
  return switch (defaultLabel) {
    'red' => _HomePalette.alertSoft,
    'orange' => _HomePalette.goldSoft,
    _ => const Color(0xFF7ED2B6),
  };
}

abstract final class _HomePalette {
  static const background = Color(0xFF071214);
  static const surface = Color(0xFF0D1A1D);
  static const surfaceRaised = Color(0xFF122327);
  static const outline = Color(0x2239A29A);
  static const teal = Color(0xFF1E6C69);
  static const tealSoft = Color(0xFF73D1BE);
  static const goldSoft = Color(0xFFE8C48F);
  static const highlight = Color(0xFFF0AA74);
  static const alert = Color(0xFFD88478);
  static const alertSoft = Color(0xFFF0A898);
  static const textPrimary = Color(0xFFF7F2E8);
  static const textSoft = Color(0xFFD8E2DE);
  static const textMuted = Color(0xFF8EA3A1);
}
