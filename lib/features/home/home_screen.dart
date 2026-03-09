import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/closeout_providers.dart';
import '../../core/providers/ledger_providers.dart';
import '../../core/providers/plant_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/models/plant_state.dart';
import '../transactions/reconcile_sheet.dart';
import '../transactions/transaction_tile_widget.dart';
import 'widgets/allowance_card.dart';
import 'widgets/behind_banner.dart';
import 'widgets/plant_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger plant state update (backfill missed days) on every home screen build.
    ref.watch(plantUpdateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sapling',
          style: TextStyle(
            fontFamily: 'Georgia', // Premium editorial serif fallback
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: SaplingColors.primary,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _BalanceCard(),
          const SizedBox(height: 12),
          const _CloseoutStatusCard(),
          const SizedBox(height: 12),
          const AllowanceCard(),
          const BehindBanner(),
          // const SizedBox(height: 20),
          // const _PlantSection(),
          const SizedBox(height: 24),
          _QuickActions(
            onAddExpense: () => context.push('/add-expense'),
            onAddIncome: () => context.push('/add-income'),
            onMarkBillPaid: () => context.go('/bills'),
            onSplits: () => context.push('/splits'),
            onReconcile: () => _showReconcile(context),
          ),
          const SizedBox(height: 24),
          _RecentTransactions(),
        ],
      ),
    );
  }

  void _showReconcile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ReconcileSheet(),
    );
  }
}

class _PlantSection extends StatefulWidget {
  const _PlantSection();

  @override
  State<_PlantSection> createState() => _PlantSectionState();
}

class _PlantSectionState extends State<_PlantSection> {
  // Debug-only local state so you can tap buttons and watch the plant change.
  PlantState _debug = PlantState.initial();

  void _grow() => setState(() {
    _debug = _debug.copyWith(
      growthPoints: _debug.growthPoints + 5,
      healthScore: (_debug.healthScore + 15).clamp(0, 100),
      currentStreak: _debug.currentStreak + 5,
      longestStreak: _debug.longestStreak + 5,
      daysAtZero: 0,
    );
  });

  void _decay() => setState(() {
    _debug = _debug.copyWith(
      healthScore: (_debug.healthScore - 12).clamp(0, 100),
      currentStreak: 0,
      daysAtZero: _debug.daysAtZero + 3,
      growthPoints:
          _debug.daysAtZero >= 7
              ? (_debug.growthPoints - 1).clamp(0, 9999)
              : _debug.growthPoints,
    );
  });

  void _reset() => setState(() {
    _debug = PlantState.initial();
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: SaplingColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              PlantWidget(state: _debug),
              const SizedBox(height: 8),
              // ── Debug controls ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _DebugBtn(label: '🌱 Grow', onTap: _grow),
                    _DebugBtn(label: '🍂 Decay', onTap: _decay),
                    _DebugBtn(label: '↻ Reset', onTap: _reset),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Growth: ${_debug.growthPoints}pts (stage ${_debug.growthStage})  •  '
                'Health: ${_debug.healthScore} (stage ${_debug.healthStage})',
                style: TextStyle(
                  fontSize: 10,
                  color: SaplingColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebugBtn extends StatelessWidget {
  const _DebugBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: SaplingColors.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: SaplingColors.primary,
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceStreamProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Current Balance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SaplingColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: SaplingColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'USD',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: SaplingColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          balanceAsync.when(
            data:
                (balance) => Text(
                  formatCurrency(balance),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 42,
                    letterSpacing: -1.5,
                    color: SaplingColors.primary,
                  ),
                ),
            loading:
                () => const SizedBox(
                  height: 48,
                  width: 150,
                  child: LinearProgressIndicator(
                    color: SaplingColors.shimmer,
                    backgroundColor: Colors.transparent,
                  ),
                ),
            error:
                (e, _) => Text(
                  'Error: $e',
                  style: const TextStyle(color: SaplingColors.error),
                ),
          ),
        ],
      ),
    );
  }
}

class _CloseoutStatusCard extends ConsumerWidget {
  const _CloseoutStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () => context.push('/closeout'),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: SaplingColors.secondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.eco, color: SaplingColors.secondary, size: 20),
              const SizedBox(width: 8),
              streakAsync.when(
                data:
                    (s) => Text(
                      '${s.currentStreak}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: SaplingColors.secondary,
                        fontSize: 16,
                      ),
                    ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Text(
                'Budget streak...',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: SaplingColors.secondary.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onMarkBillPaid,
    required this.onSplits,
    required this.onReconcile,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onMarkBillPaid;
  final VoidCallback onSplits;
  final VoidCallback onReconcile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionButton(
            icon: Icons.horizontal_rule_rounded,
            label: 'Expense',
            color: SaplingColors.accent,
            onTap: onAddExpense,
          ),
          _ActionButton(
            icon: Icons.attach_money_rounded,
            label: 'Income',
            color: SaplingColors.secondary,
            onTap: onAddIncome,
          ),
          _ActionButton(
            icon: Icons.receipt_long_rounded,
            label: 'Pay Bill',
            color: SaplingColors.surfaceNav,
            onTap: onMarkBillPaid,
            iconColor: Colors.white,
          ),
          _ActionButton(
            icon: Icons.call_split_rounded,
            label: 'Split',
            color: SaplingColors.secondary.withValues(alpha: 0.4),
            onTap: onSplits,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: color.withValues(alpha: color.a == 1.0 ? 0.15 : 1.0),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: color.a == 1.0 ? 0.15 : 1.0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color:
                      iconColor ??
                      (color.a == 1.0 ? color : SaplingColors.primary),
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: SaplingColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _RecentTransactions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(recentTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2625), // Very dark slate/black
              ),
            ),
            TextButton(
              onPressed: () => context.push('/transactions'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View all',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A918B), // Soft teal
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        txnAsync.when(
          data: (txns) {
            if (txns.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No transactions yet.',
                    style: TextStyle(color: SaplingColors.textSecondary),
                  ),
                ),
              );
            }
            final recent = txns.take(5).toList();
            return Column(
              children:
                  recent
                      .map((t) => SmallTransactionTile(transaction: t))
                      .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}
