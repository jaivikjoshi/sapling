import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/ledger_providers.dart';
import '../../core/providers/split_providers.dart';
import '../../data/db/sapling_database.dart';
import '../../domain/models/enums.dart';
import '../../core/utils/enum_serialization.dart';

class EditExpenseScreen extends ConsumerStatefulWidget {
  const EditExpenseScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  ConsumerState<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends ConsumerState<EditExpenseScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String? _categoryId;
  SpendLabel? _label;
  Transaction? _txn;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final txn = await ref.read(ledgerServiceProvider).getTransactionById(widget.transactionId);
    if (txn == null || txn.type != 'expense') {
      if (mounted) context.pop();
      return;
    }
    setState(() {
      _txn = txn;
      _amountCtrl.text = txn.amount.toStringAsFixed(2);
      _noteCtrl.text = txn.note ?? '';
      _date = txn.date;
      _categoryId = txn.categoryId;
      _label = txn.label != null
          ? enumFromDb<SpendLabel>(txn.label!, SpendLabel.values)
          : SpendLabel.green;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _txn != null &&
      _amountCtrl.text.isNotEmpty &&
      (double.tryParse(_amountCtrl.text) ?? 0) > 0 &&
      _categoryId != null;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Expense')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_txn == null) return const SizedBox.shrink();

    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              prefixText: '\$ ',
              labelText: 'Amount',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          categoriesAsync.when(
            data: (cats) => DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (id) => setState(() => _categoryId = id),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 16),
          _DateTile(date: _date, onTap: _pickDate),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isValid && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_isValid || _txn == null) return;
    final newAmount = double.parse(_amountCtrl.text);
    final linkedId = _txn!.linkedSplitEntryId;

    bool updateLinkedSplit = false;
    if (linkedId != null && (newAmount != _txn!.amount)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Update linked split?'),
          content: const Text(
            'This expense is linked to a split. Update the linked split amount too?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      updateLinkedSplit = confirmed == true;
    }

    setState(() => _saving = true);
    try {
      if (updateLinkedSplit && linkedId != null) {
        await ref.read(splitServiceProvider).updateSplitFromExpenseAmount(linkedId, newAmount);
      }
      await ref.read(ledgerServiceProvider).updateExpense(
            id: widget.transactionId,
            amount: newAmount,
            date: _date,
            categoryId: _categoryId,
            label: _label,
            note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
          );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Date'),
        child: Text('${date.month}/${date.day}/${date.year}'),
      ),
    );
  }
}
