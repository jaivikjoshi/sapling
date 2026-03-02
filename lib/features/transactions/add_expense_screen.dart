import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/ledger_providers.dart';
import '../../core/providers/recovery_providers.dart';
import '../../core/providers/scheduler_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/providers/widget_snapshot_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../data/db/sapling_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/category_service.dart';
import '../recovery/overspend_modal.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  Category? _selectedCategory;
  SpendLabel? _labelOverride;
  bool _saving = false;

  SpendLabel get _effectiveLabel {
    if (_labelOverride != null) return _labelOverride!;
    if (_selectedCategory != null) {
      return LabelRules.defaultForCategory(_selectedCategory!);
    }
    return SpendLabel.green;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _amountCtrl.text.isNotEmpty &&
      (double.tryParse(_amountCtrl.text) ?? 0) > 0 &&
      _selectedCategory != null;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: const InputDecoration(
              prefixText: '\$ ',
              hintText: '0.00',
              labelText: 'Amount',
            ),
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          categoriesAsync.when(
            data: (cats) => _CategoryPickerWithLabel(
              categories: cats,
              selected: _selectedCategory,
              onChanged: (cat) => setState(() {
                _selectedCategory = cat;
                _labelOverride = null;
              }),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading categories: $e'),
          ),
          const SizedBox(height: 16),
          _LabelOverridePicker(
            effectiveLabel: _effectiveLabel,
            isOverridden: _labelOverride != null,
            onChanged: (l) => setState(() => _labelOverride = l),
            onReset: () => setState(() => _labelOverride = null),
          ),
          const SizedBox(height: 16),
          _DateTile(date: _date, onTap: _pickDate),
          const SizedBox(height: 16),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'What was this for?',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isValid && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Expense'),
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
    setState(() => _saving = true);
    try {
      final txnId = await ref.read(ledgerServiceProvider).addExpense(
            amount: double.parse(_amountCtrl.text),
            date: _date,
            categoryId: _selectedCategory!.id,
            label: _effectiveLabel,
            note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
          );

      if (!mounted) return;

      // PRD 5.12: After saving an expense, check for overspend
      await _checkOverspend(txnId);
      ref.read(snapshotWriterProvider).writeSnapshot();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _checkOverspend(String txnId) async {
    final settings = ref.read(settingsStreamProvider).valueOrNull;
    if (settings == null) {
      if (mounted) context.pop();
      return;
    }

    final detector = ref.read(overspendDetectorProvider);
    final result = await detector.detect(settings: settings);

    if (!mounted) return;

    if (result.isOverspent) {
      if (settings.overspendEnabled) {
        ref.read(notificationSchedulerProvider).showOverspendNow();
      }
      context.pop();
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => OverspendModal(
          result: result,
          triggerTransactionId: txnId,
        ),
      );
    } else {
      context.pop();
    }
  }
}

class _CategoryPickerWithLabel extends StatelessWidget {
  const _CategoryPickerWithLabel({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selected?.id,
      decoration: const InputDecoration(labelText: 'Category'),
      items: categories.map((c) {
        final color = _labelColor(c.defaultLabel);
        return DropdownMenuItem(
          value: c.id,
          child: Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 10),
              Text(c.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (id) {
        if (id != null) {
          onChanged(categories.firstWhere((c) => c.id == id));
        }
      },
    );
  }

  Color _labelColor(String label) => switch (label) {
        'orange' => SaplingColors.labelOrange,
        'red' => SaplingColors.labelRed,
        _ => SaplingColors.labelGreen,
      };
}

class _LabelOverridePicker extends StatelessWidget {
  const _LabelOverridePicker({
    required this.effectiveLabel,
    required this.isOverridden,
    required this.onChanged,
    required this.onReset,
  });

  final SpendLabel effectiveLabel;
  final bool isOverridden;
  final ValueChanged<SpendLabel> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Label',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: SaplingColors.textSecondary),
            ),
            if (isOverridden) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onReset,
                child: Text(
                  '(reset to default)',
                  style: TextStyle(
                    color: SaplingColors.secondary,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: SpendLabel.values.map((l) {
            final color = _colorFor(l);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(l.name),
                selected: effectiveLabel == l,
                selectedColor: color.withValues(alpha: 0.2),
                avatar: Icon(Icons.circle, size: 12, color: color),
                onSelected: (_) => onChanged(l),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _colorFor(SpendLabel l) => switch (l) {
        SpendLabel.green => SaplingColors.labelGreen,
        SpendLabel.orange => SaplingColors.labelOrange,
        SpendLabel.red => SaplingColors.labelRed,
      };
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
