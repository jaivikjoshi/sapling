import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/bills_providers.dart';
import '../../core/providers/ledger_providers.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/sapling_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/bills_service.dart';

class BillFormSheet extends ConsumerStatefulWidget {
  const BillFormSheet({super.key, this.existing});
  final Bill? existing;

  @override
  ConsumerState<BillFormSheet> createState() => _BillFormSheetState();
}

class _BillFormSheetState extends ConsumerState<BillFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late BillFrequency _frequency;
  late DateTime _nextDueDate;
  String? _categoryId;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountCtrl = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2) : '',
    );
    _frequency =
        e != null
            ? enumFromDb<BillFrequency>(e.frequency, BillFrequency.values)
            : BillFrequency.monthly;
    _nextDueDate = e?.nextDueDate ?? DateTime.now();
    _categoryId = e?.categoryId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit Bill' : 'New Bill',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildNameField(),
              const SizedBox(height: 12),
              _buildAmountField(),
              const SizedBox(height: 12),
              _buildFrequencyPicker(),
              const SizedBox(height: 12),
              _buildDatePicker(),
              const SizedBox(height: 12),
              _buildCategoryPicker(catsAsync),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      decoration: const InputDecoration(labelText: 'Bill Name'),
      validator: (v) => BillsService.validateName(v ?? ''),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountCtrl,
      decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (v) => BillsService.validateAmount(double.tryParse(v ?? '')),
    );
  }

  Widget _buildFrequencyPicker() {
    return DropdownButtonFormField<BillFrequency>(
      value: _frequency,
      decoration: const InputDecoration(labelText: 'Frequency'),
      items:
          BillFrequency.values
              .map((f) => DropdownMenuItem(value: f, child: Text(f.name)))
              .toList(),
      onChanged: (v) => setState(() => _frequency = v!),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Next Due Date'),
      subtitle: Text(DateFormat.yMMMd().format(_nextDueDate)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _nextDueDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2040),
        );
        if (picked != null) setState(() => _nextDueDate = picked);
      },
    );
  }

  Widget _buildCategoryPicker(AsyncValue<List<Category>> catsAsync) {
    return catsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Error loading categories: $e'),
      data: (cats) {
        if (_categoryId == null && cats.isNotEmpty) {
          _categoryId = cats.first.id;
        }
        return DropdownButtonFormField<String>(
          value: _categoryId,
          decoration: const InputDecoration(labelText: 'Category'),
          items:
              cats
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
          onChanged: (v) => setState(() => _categoryId = v),
          validator:
              (v) => v == null || v.isEmpty ? 'Category is required.' : null,
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text);
    final service = ref.read(billsServiceProvider);

    if (_isEditing) {
      await service.update(
        id: widget.existing!.id,
        name: _nameCtrl.text,
        amount: amount,
        frequency: _frequency,
        nextDueDate: _nextDueDate,
        categoryId: _categoryId!,
        defaultLabel: SpendLabel.green,
      );
    } else {
      await service.create(
        name: _nameCtrl.text,
        amount: amount,
        frequency: _frequency,
        nextDueDate: _nextDueDate,
        categoryId: _categoryId!,
        defaultLabel: SpendLabel.green,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}
