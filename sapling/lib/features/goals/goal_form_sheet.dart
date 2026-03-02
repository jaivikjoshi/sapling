import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/goals_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/sapling_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/goals_service.dart';

class GoalFormSheet extends ConsumerStatefulWidget {
  const GoalFormSheet({super.key, this.existing});
  final Goal? existing;

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late SavingStyle _style;
  late DateTime _targetDate;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _amountCtrl = TextEditingController(
      text: e != null ? e.targetAmount.toStringAsFixed(2) : '',
    );
    _style = e != null
        ? enumFromDb<SavingStyle>(e.savingStyle, SavingStyle.values)
        : SavingStyle.natural;
    _targetDate = e?.targetDate ??
        DateTime.now().add(const Duration(days: 90));
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
        left: 20, right: 20, top: 20,
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
                _isEditing ? 'Edit Goal' : 'New Goal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildNameField(),
              const SizedBox(height: 12),
              _buildAmountField(),
              const SizedBox(height: 12),
              _buildDatePicker(),
              const SizedBox(height: 12),
              _buildStylePicker(),
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
      decoration: const InputDecoration(labelText: 'Goal Name'),
      validator: (v) => GoalsService.validateName(v ?? ''),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountCtrl,
      decoration: const InputDecoration(
        labelText: 'Target Amount',
        prefixText: '\$ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (v) =>
          GoalsService.validateAmount(double.tryParse(v ?? '')),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Target Date'),
      subtitle: Text(DateFormat.yMMMd().format(_targetDate)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _targetDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2050),
        );
        if (picked != null) setState(() => _targetDate = picked);
      },
    );
  }

  Widget _buildStylePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Saving Style',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: SaplingColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: SavingStyle.values.map((s) {
            final selected = s == _style;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(s.name),
                selected: selected,
                selectedColor: _styleColor(s).withValues(alpha: 0.3),
                onSelected: (_) => setState(() => _style = s),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          _styleHint(_style),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: SaplingColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Color _styleColor(SavingStyle s) => switch (s) {
        SavingStyle.easy => SaplingColors.labelGreen,
        SavingStyle.natural => SaplingColors.labelOrange,
        SavingStyle.aggressive => SaplingColors.labelRed,
      };

  String _styleHint(SavingStyle s) => switch (s) {
        SavingStyle.easy => 'Full variable spending allowed (×1.00)',
        SavingStyle.natural => 'Moderate savings pressure (×0.90)',
        SavingStyle.aggressive => 'Strict savings mode (×0.75)',
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text);
    final dateErr = GoalsService.validateDate(_targetDate);
    if (dateErr != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(dateErr)));
      return;
    }

    final service = ref.read(goalsServiceProvider);

    if (_isEditing) {
      await service.update(
        id: widget.existing!.id,
        name: _nameCtrl.text,
        targetAmount: amount,
        targetDate: _targetDate,
        savingStyle: _style,
      );
    } else {
      await service.create(
        name: _nameCtrl.text,
        targetAmount: amount,
        targetDate: _targetDate,
        savingStyle: _style,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}
