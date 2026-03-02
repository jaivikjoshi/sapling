import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/sapling_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/db/sapling_database.dart';

class SmallTransactionTile extends StatelessWidget {
  const SmallTransactionTile({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';

    final color = isExpense
        ? SaplingColors.labelRed
        : isIncome
            ? SaplingColors.labelGreen
            : SaplingColors.support;

    final sign = isExpense
        ? '-'
        : (transaction.type == 'adjustment' && transaction.amount < 0)
            ? ''
            : '+';

    final dateStr = DateFormat.MMMd().format(transaction.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isExpense
                  ? Icons.arrow_downward
                  : isIncome
                      ? Icons.arrow_upward
                      : Icons.sync_alt,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(dateStr,
                      style: TextStyle(
                          color: SaplingColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text(
              '$sign${formatCurrency(transaction.amount.abs())}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
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
      'adjustment' => 'Adjustment',
      _ => 'Transaction',
    };
  }
}
