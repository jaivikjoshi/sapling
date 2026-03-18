import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/ledger_providers.dart';
import '../../core/theme/leko_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/db/leko_database.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: txnAsync.when(
        data: (txns) => txns.isEmpty
            ? const Center(child: Text('No transactions yet.'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: txns.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) =>
                    TransactionTile(transaction: txns[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';
    final isAdjustment = transaction.type == 'adjustment';

    final icon = isExpense
        ? Icons.arrow_downward
        : isIncome
            ? Icons.arrow_upward
            : Icons.sync_alt;

    final color = isExpense
        ? LekoColors.labelRed
        : isIncome
            ? LekoColors.labelGreen
            : LekoColors.support;

    final sign = isExpense
        ? '-'
        : isAdjustment && transaction.amount < 0
            ? ''
            : '+';

    final dateStr = DateFormat.MMMd().format(transaction.date);
    final onTap = isExpense
        ? () => context.push('/edit-expense/${transaction.id}')
        : null;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        _title,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$dateStr • ${transaction.type}',
        style: TextStyle(color: LekoColors.textSecondary, fontSize: 12),
      ),
      trailing: Text(
        '$sign${formatCurrency(transaction.amount.abs())}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  String get _title {
    if (transaction.note != null && transaction.note!.isNotEmpty) {
      return transaction.note!;
    }
    return switch (transaction.type) {
      'expense' => 'Expense',
      'income' => transaction.source ?? 'Income',
      'adjustment' => 'Balance adjustment',
      _ => 'Transaction',
    };
  }
}
