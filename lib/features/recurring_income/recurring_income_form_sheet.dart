import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/recurring_income_providers.dart';
import '../../core/theme/leko_colors.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/recurring_income_service.dart';

class RecurringIncomeFormSheet extends ConsumerStatefulWidget {
  const RecurringIncomeFormSheet({super.key, this.existing});
  final RecurringIncome? existing;

  @override
  ConsumerState<RecurringIncomeFormSheet> createState() =>
      _RecurringIncomeFormSheetState();
}

class _RecurringIncomeFormSheetState
    extends ConsumerState<RecurringIncomeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late IncomeFrequency _frequency;
  late PaydayBehavior _behavior;
  late DateTime _nextPaydayDate;
  late bool _isAnchor;
  String? _autoPostError;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountCtrl = TextEditingController(
      text: e?.expectedAmount?.toStringAsFixed(2) ?? '',
    );
    _frequency = e != null
        ? enumFromDb<IncomeFrequency>(e.frequency, IncomeFrequency.values)
        : IncomeFrequency.monthly;
    _behavior = e != null
        ? enumFromDb<PaydayBehavior>(e.paydayBehavior, PaydayBehavior.values)
        : PaydayBehavior.confirmActualOnPayday;
    _nextPaydayDate = e?.nextPaydayDate ?? DateTime.now();
    _isAnchor = e?.isPaydayAnchor ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit Income Schedule' : 'New Income Schedule',
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
              _buildBehaviorPicker(),
              if (_autoPostError != null) ...[
                const SizedBox(height: 4),
                Text(_autoPostError!,
                    style: TextStyle(color: LekoColors.error, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              _buildAnchorToggle(),
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
      decoration: const InputDecoration(labelText: 'Name'),
      validator: (v) => RecurringIncomeService.validateName(v ?? ''),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountCtrl,
      decoration: const InputDecoration(
        labelText: 'Expected Amount (optional)',
        prefixText: '\$ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
    );
  }

  Widget _buildFrequencyPicker() {
    return DropdownButtonFormField<IncomeFrequency>(
      value: _frequency,
      decoration: const InputDecoration(labelText: 'Frequency'),
      items: IncomeFrequency.values
          .map((f) => DropdownMenuItem(value: f, child: Text(f.name)))
          .toList(),
      onChanged: (v) => setState(() => _frequency = v!),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Next Payday Date'),
      subtitle: Text(DateFormat.yMMMd().format(_nextPaydayDate)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _nextPaydayDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2040),
        );
        if (picked != null) setState(() => _nextPaydayDate = picked);
      },
    );
  }

  Widget _buildBehaviorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payday Behavior',
            style: TextStyle(fontSize: 12, color: LekoColors.textSecondary)),
        RadioListTile<PaydayBehavior>(
          value: PaydayBehavior.confirmActualOnPayday,
          groupValue: _behavior,
          title: const Text('Confirm actual on payday'),
          dense: true,
          onChanged: (v) => setState(() {
            _behavior = v!;
            _autoPostError = null;
          }),
        ),
        RadioListTile<PaydayBehavior>(
          value: PaydayBehavior.autoPostExpected,
          groupValue: _behavior,
          title: const Text('Auto-post expected'),
          dense: true,
          onChanged: (v) => setState(() {
            _behavior = v!;
            _validateAutoPost();
          }),
        ),
      ],
    );
  }

  Widget _buildAnchorToggle() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Set as Payday Anchor'),
      subtitle: const Text('Only one schedule can be the anchor'),
      value: _isAnchor,
      onChanged: (v) => setState(() => _isAnchor = v),
    );
  }

  void _validateAutoPost() {
    final amount = double.tryParse(_amountCtrl.text);
    _autoPostError = RecurringIncomeService.validateAutoPost(
      behavior: _behavior,
      expectedAmount: amount,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text);

    _validateAutoPost();
    if (_autoPostError != null) {
      setState(() {});
      return;
    }

    final service = ref.read(recurringIncomeServiceProvider);

    if (_isEditing) {
      await service.update(
        id: widget.existing!.id,
        name: _nameCtrl.text,
        frequency: _frequency,
        nextPaydayDate: _nextPaydayDate,
        expectedAmount: amount,
        paydayBehavior: _behavior,
      );
      if (_isAnchor) {
        await service.setPaydayAnchor(widget.existing!.id);
      } else if (widget.existing!.isPaydayAnchor && !_isAnchor) {
        await service.clearPaydayAnchor();
      }
    } else {
      await service.create(
        name: _nameCtrl.text,
        frequency: _frequency,
        nextPaydayDate: _nextPaydayDate,
        expectedAmount: amount,
        paydayBehavior: _behavior,
        isPaydayAnchor: _isAnchor,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}
