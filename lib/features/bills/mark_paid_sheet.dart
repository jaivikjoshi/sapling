import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/bills_providers.dart';
import '../../core/providers/widget_snapshot_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../data/db/sapling_database.dart';

class MarkPaidSheet extends ConsumerStatefulWidget {
  const MarkPaidSheet({super.key, required this.bill});
  final Bill bill;

  @override
  ConsumerState<MarkPaidSheet> createState() => _MarkPaidSheetState();
}

class _MarkPaidSheetState extends ConsumerState<MarkPaidSheet> {
  late TextEditingController _amountCtrl;
  late DateTime _paidDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.bill.amount.toStringAsFixed(2),
    );
    _paidDate = DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mark Paid', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(widget.bill.name,
              style: TextStyle(
                  color: SaplingColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountCtrl,
            decoration: const InputDecoration(
              labelText: 'Amount Paid',
              prefixText: '\$ ',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Paid Date'),
            subtitle: Text(DateFormat.yMMMd().format(_paidDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _paidDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _paidDate = picked);
            },
          ),
          const SizedBox(height: 16),
          Text(
            'This creates an expense transaction and advances the '
            'next due date.',
            style: TextStyle(
                color: SaplingColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _markPaid,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _markPaid() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    final service = ref.read(billsServiceProvider);
    final result = await service.markPaid(
      billId: widget.bill.id,
      paidDate: _paidDate,
      amountOverride: amount != widget.bill.amount ? amount : null,
    );

    if (!mounted) return;
    ref.read(snapshotWriterProvider).writeSnapshot();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.bill.name} paid — \$${result.paidAmount.toStringAsFixed(2)}',
        ),
      ),
    );
  }
}
