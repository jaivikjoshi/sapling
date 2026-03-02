import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/closeout_providers.dart';
import '../../core/providers/ledger_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../transactions/reconcile_sheet.dart';
import '../transactions/transaction_tile_widget.dart';
import 'widgets/allowance_card.dart';
import 'widgets/behind_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                height: 32,
                width: 32,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Sapling'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.splitscreen),
            tooltip: 'Friends & Split',
            onPressed: () => context.push('/splits'),
          ),
        ],
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

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceStreamProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Balance',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: SaplingColors.textSecondary),
            ),
            const SizedBox(height: 8),
            balanceAsync.when(
              data: (balance) => Text(
                formatCurrency(balance),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: SaplingColors.primary,
                    ),
              ),
              loading: () => const SizedBox(
                height: 36,
                width: 100,
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text('Error: $e',
                  style: TextStyle(color: SaplingColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseoutStatusCard extends ConsumerWidget {
  const _CloseoutStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return Card(
      child: InkWell(
        onTap: () => context.push('/closeout'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.nightlight_round, color: SaplingColors.support),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    streakAsync.when(
                      data: (s) => Text(
                        '${s.currentStreak} day budget streak',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      loading: () => const Text('Budget streak…'),
                      error: (_, __) => const Text('Closeout'),
                    ),
                    const SizedBox(height: 2),
                    streakAsync.when(
                      data: (s) => Text(
                        s.todayWithinBudget ? 'Today: within budget' : 'Today: over budget',
                        style: TextStyle(
                          fontSize: 12,
                          color: s.todayWithinBudget
                              ? SaplingColors.labelGreen
                              : SaplingColors.labelRed,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: SaplingColors.textSecondary),
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionButton(
          icon: Icons.remove_circle_outline,
          label: 'Expense',
          color: SaplingColors.labelRed,
          onTap: onAddExpense,
        ),
        _ActionButton(
          icon: Icons.add_circle_outline,
          label: 'Income',
          color: SaplingColors.secondary,
          onTap: onAddIncome,
        ),
        _ActionButton(
          icon: Icons.receipt,
          label: 'Pay Bill',
          color: SaplingColors.labelOrange,
          onTap: onMarkBillPaid,
        ),
        _ActionButton(
          icon: Icons.splitscreen,
          label: 'Friends & Split',
          color: SaplingColors.support,
          onTap: onSplits,
        ),
        _ActionButton(
          icon: Icons.sync_alt,
          label: 'Reconcile',
          color: SaplingColors.support,
          onTap: onReconcile,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 32 - 12) / 2;
    return SizedBox(
      width: width,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
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
            Text('Recent',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            TextButton(
              onPressed: () => context.push('/transactions'),
              child: const Text('View all'),
            ),
          ],
        ),
        txnAsync.when(
          data: (txns) {
            if (txns.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No transactions yet.',
                      style: TextStyle(color: SaplingColors.textSecondary)),
                ),
              );
            }
            final recent = txns.take(5).toList();
            return Column(
              children: recent
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
