import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/goals_providers.dart';
import '../../core/theme/leko_colors.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
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
    _style =
        e != null
            ? enumFromDb<SavingStyle>(e.savingStyle, SavingStyle.values)
            : SavingStyle.natural;
    _targetDate = e?.targetDate ?? DateTime.now().add(const Duration(days: 90));
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: LekoColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _isEditing ? 'Edit Goal' : 'New Goal',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: LekoColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildNameField(),
              const SizedBox(height: 16),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 24),
              _buildStylePicker(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LekoColors.textPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isEditing ? 'UPDATE GOAL' : 'SAVE GOAL',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
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
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: 'Goal Name',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) => GoalsService.validateName(v ?? ''),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountCtrl,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: 'Target Amount',
        prefixText: '\$ ',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      validator: (v) => GoalsService.validateAmount(double.tryParse(v ?? '')),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Target Date',
          style: TextStyle(color: LekoColors.textSecondary, fontSize: 13),
        ),
        subtitle: Text(
          DateFormat.yMMMd().format(_targetDate),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: LekoColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.calendar_today_rounded,
          color: LekoColors.textSecondary,
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _targetDate,
            firstDate: DateTime.now(),
            lastDate: DateTime(2050),
          );
          if (picked != null) setState(() => _targetDate = picked);
        },
      ),
    );
  }

  Widget _buildStylePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Saving Style',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: LekoColors.textSecondary),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                SavingStyle.values.map((s) {
                  final selected = s == _style;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        s.name,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: selected,
                      showCheckmark: false,
                      backgroundColor: Colors.white,
                      selectedColor: _styleColor(s).withValues(alpha: 0.15),
                      side: BorderSide(
                        color: selected ? _styleColor(s) : Colors.transparent,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (_) => setState(() => _style = s),
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            _styleHint(_style),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LekoColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _styleColor(SavingStyle s) => switch (s) {
    SavingStyle.easy => LekoColors.labelGreen,
    SavingStyle.natural => LekoColors.labelOrange,
    SavingStyle.aggressive => LekoColors.labelRed,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(dateErr)));
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
