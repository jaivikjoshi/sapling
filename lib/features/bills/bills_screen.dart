import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/bills_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/sapling_database.dart';
import '../../domain/models/enums.dart';
import 'bill_form_sheet.dart';
import 'mark_paid_sheet.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bills')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'bills_fab',
        onPressed: () => _showForm(context),
        backgroundColor: SaplingColors.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bills) =>
            bills.isEmpty ? const _EmptyState() : _BillsList(bills: bills),
      ),
    );
  }

  void _showForm(BuildContext context, {Bill? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BillFormSheet(existing: existing),
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
          Icon(Icons.receipt_long_outlined,
              size: 64, color: SaplingColors.textSecondary),
          const SizedBox(height: 16),
          Text('No bills yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Tap + to add a recurring bill',
              style: TextStyle(color: SaplingColors.textSecondary)),
        ],
      ),
    );
  }
}

class _BillsList extends ConsumerWidget {
  const _BillsList({required this.bills});
  final List<Bill> bills;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: bills.length,
      itemBuilder: (ctx, i) => _BillTile(bill: bills[i]),
    );
  }
}

class _BillTile extends ConsumerWidget {
  const _BillTile({required this.bill});
  final Bill bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freq =
        enumFromDb<BillFrequency>(bill.frequency, BillFrequency.values);
    final label =
        enumFromDb<SpendLabel>(bill.defaultLabel, SpendLabel.values);
    final labelColor = _labelColor(label);
    final dateFmt = DateFormat.yMMMd();
    final daysUntil =
        bill.nextDueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntil < 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: labelColor.withValues(alpha: 0.15),
          child: Icon(Icons.receipt, color: labelColor, size: 20),
        ),
        title: Text(bill.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${freq.name} · \$${bill.amount.toStringAsFixed(2)} · '
          '${isOverdue ? "Overdue" : "Due ${dateFmt.format(bill.nextDueDate)}"}',
          style: TextStyle(
            color: isOverdue ? SaplingColors.error : SaplingColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => _onAction(context, ref, v),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'pay', child: Text('Mark Paid')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showMarkPaid(context),
      ),
    );
  }

  void _onAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'pay':
        _showMarkPaid(context);
      case 'edit':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => BillFormSheet(existing: bill),
        );
      case 'delete':
        _confirmDelete(context, ref);
    }
  }

  void _showMarkPaid(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MarkPaidSheet(bill: bill),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text('Delete "${bill.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(billsServiceProvider).delete(bill.id);
            },
            child: Text('Delete',
                style: TextStyle(color: SaplingColors.error)),
          ),
        ],
      ),
    );
  }

  Color _labelColor(SpendLabel label) => switch (label) {
        SpendLabel.green => SaplingColors.labelGreen,
        SpendLabel.orange => SaplingColors.labelOrange,
        SpendLabel.red => SaplingColors.labelRed,
      };
}
