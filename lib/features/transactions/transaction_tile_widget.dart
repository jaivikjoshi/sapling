import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/leko_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/db/leko_database.dart';

class SmallTransactionTile extends StatelessWidget {
  const SmallTransactionTile({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final isIncome = transaction.type == 'income';
    final isAdjustment = transaction.type == 'adjustment';

    // Soft custom colors matching the screenshot
    final amountColor =
        isExpense
            ? const Color(0xFFD6A28E) // Soft terracotta/coral for expense
            : isIncome
            ? const Color(0xFF8DBBA6) // Soft teal/green for income
            : const Color(0xFFC0A68D); // Soft tan for adjustment

    final iconColor =
        isExpense
            ? const Color(0xFFD6A28E)
            : isIncome
            ? const Color(0xFF8DBBA6)
            : const Color(
              0xFFD6A28E,
            ); // The screenshot has a soft terracotta sync icon

    final sign =
        isExpense
            ? '-'
            : (isAdjustment && transaction.amount < 0)
            ? ''
            : '+';

    final dateStr = DateFormat.MMMd().format(transaction.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color:
            LekoColors
                .surface, // Or Colors.white if the background is off-white
        borderRadius: BorderRadius.circular(24), // Pill shape
      ),
      child: Row(
        children: [
          Icon(
            isExpense
                ? Icons.arrow_downward
                : isIncome
                ? Icons.arrow_upward
                : Icons.sync_alt,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF819297), // Slate grey text
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Color(0xFFA5B4B9), // Lighter slate grey for date
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$sign${formatCurrency(transaction.amount.abs())}',
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
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
