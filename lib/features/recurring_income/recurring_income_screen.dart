import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/recurring_income_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../domain/services/recurring_income_service.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/sapling_database.dart';
import '../../domain/models/enums.dart';
import 'recurring_income_form_sheet.dart';

class RecurringIncomeScreen extends ConsumerWidget {
  const RecurringIncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomesAsync = ref.watch(recurringIncomesProvider);
    final service = ref.watch(recurringIncomeServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Income')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'recurring_income_fab',
        onPressed: () => _showForm(context),
        backgroundColor: SaplingColors.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: incomesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (incomes) => incomes.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: incomes.length,
                itemBuilder: (ctx, i) => _IncomeTile(
                  income: incomes[i],
                  onEdit: () => _showForm(ctx, existing: incomes[i]),
                  onDelete: () => _confirmDelete(ctx, service, incomes[i]),
                  onSetAnchor: () async {
                    await service.setPaydayAnchor(incomes[i].id);
                  },
                ),
              ),
      ),
    );
  }

  void _showForm(BuildContext context, {RecurringIncome? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RecurringIncomeFormSheet(existing: existing),
    );
  }

  void _confirmDelete(
    BuildContext context,
    RecurringIncomeService service,
    RecurringIncome income,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Income Schedule'),
        content: Text('Delete "${income.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await service.delete(income.id);
            },
            child: Text('Delete',
                style: TextStyle(color: SaplingColors.error)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 64, color: SaplingColors.textSecondary),
          const SizedBox(height: 16),
          Text('No recurring income yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Tap + to add an income schedule',
              style: TextStyle(color: SaplingColors.textSecondary)),
        ],
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  const _IncomeTile({
    required this.income,
    required this.onEdit,
    required this.onDelete,
    required this.onSetAnchor,
  });

  final RecurringIncome income;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetAnchor;

  @override
  Widget build(BuildContext context) {
    final freq = enumFromDb<IncomeFrequency>(
      income.frequency,
      IncomeFrequency.values,
    );
    final behavior = enumFromDb<PaydayBehavior>(
      income.paydayBehavior,
      PaydayBehavior.values,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildLeading(),
        title: Text(income.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: _buildSubtitle(freq, behavior),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
            if (v == 'anchor') onSetAnchor();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            if (!income.isPaydayAnchor)
              const PopupMenuItem(
                  value: 'anchor', child: Text('Set as Payday Anchor')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }

  Widget _buildLeading() {
    return CircleAvatar(
      backgroundColor:
          income.isPaydayAnchor ? SaplingColors.secondary : SaplingColors.support,
      child: Icon(
        income.isPaydayAnchor ? Icons.star : Icons.attach_money,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildSubtitle(IncomeFrequency freq, PaydayBehavior behavior) {
    final dateFmt = DateFormat.yMMMd();
    final parts = <String>[
      freq.name,
      'Next: ${dateFmt.format(income.nextPaydayDate)}',
    ];
    if (income.expectedAmount != null) {
      parts.add('\$${income.expectedAmount!.toStringAsFixed(2)}');
    }
    if (behavior == PaydayBehavior.autoPostExpected) {
      parts.add('Auto-post');
    }
    if (income.isPaydayAnchor) {
      parts.add('⚓ Anchor');
    }
    return Text(parts.join(' · '),
        style: TextStyle(color: SaplingColors.textSecondary, fontSize: 12));
  }
}
