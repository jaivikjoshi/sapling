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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _GoalFormPalette.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: _GoalFormPalette.handle,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Text(
                    _isEditing ? 'Edit Goal' : 'New Goal',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _GoalFormPalette.textPrimary,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isEditing
                        ? 'Refine the details and keep it feeling realistic.'
                        : 'Create a calm target to save toward.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _GoalFormPalette.textSecondary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildNameField(),
                  const SizedBox(height: 16),
                  _buildAmountField(),
                  const SizedBox(height: 16),
                  _buildDatePicker(),
                  const SizedBox(height: 24),
                  _buildStylePicker(),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _GoalFormPalette.cta,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isEditing ? 'Update goal' : 'Save goal',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameCtrl,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: _GoalFormPalette.textPrimary,
        fontSize: 16,
      ),
      decoration: _fieldDecoration(label: 'Goal name', hint: 'Emergency Fund'),
      validator: (v) => GoalsService.validateName(v ?? ''),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountCtrl,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: _GoalFormPalette.textPrimary,
        fontSize: 16,
      ),
      decoration: _fieldDecoration(
        label: 'Target amount',
        prefixText: '\$ ',
        hint: '5000',
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F1932),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Target date',
          style: TextStyle(color: _GoalFormPalette.textSecondary, fontSize: 14),
        ),
        subtitle: Text(
          DateFormat.yMMMd().format(_targetDate),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: _GoalFormPalette.textPrimary,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(
          Icons.calendar_today_rounded,
          color: _GoalFormPalette.textSecondary,
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _targetDate,
            firstDate: DateTime.now(),
            lastDate: DateTime(2050),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: _GoalFormPalette.cta,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: _GoalFormPalette.textPrimary,
                  ),
                ),
                child: child!,
              );
            },
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _GoalFormPalette.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
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
                          color:
                              selected
                                  ? (s == SavingStyle.natural
                                      ? _GoalFormPalette.cta
                                      : _styleColor(s))
                                  : _GoalFormPalette.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      selected: selected,
                      showCheckmark: false,
                      backgroundColor: Colors.white,
                      selectedColor: _styleChipColor(s),
                      side: BorderSide(
                        color:
                            selected
                                ? _styleBorderColor(s)
                                : _GoalFormPalette.chipBorder,
                        width: selected ? 1.5 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
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
              color: _GoalFormPalette.textSecondary,
              fontSize: 13,
              height: 1.4,
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

  Color _styleChipColor(SavingStyle s) => switch (s) {
    SavingStyle.easy => LekoColors.labelGreen.withValues(alpha: 0.12),
    SavingStyle.natural => const Color(0xFFFFF3EA),
    SavingStyle.aggressive => LekoColors.labelRed.withValues(alpha: 0.10),
  };

  Color _styleBorderColor(SavingStyle s) => switch (s) {
    SavingStyle.easy => LekoColors.labelGreen,
    SavingStyle.natural => const Color(0xFFE39B67),
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

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      labelStyle: const TextStyle(
        color: _GoalFormPalette.textSecondary,
        fontSize: 15,
      ),
      hintStyle: const TextStyle(
        color: _GoalFormPalette.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      prefixStyle: const TextStyle(
        color: _GoalFormPalette.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: _GoalFormPalette.cta, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFD47B72), width: 1.1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: Color(0xFFD47B72), width: 1.2),
      ),
    );
  }
}

abstract final class _GoalFormPalette {
  static const background = Color(0xFFF4F5F8);
  static const textPrimary = Color(0xFF11182C);
  static const textSecondary = Color(0xFF7F8A9E);
  static const handle = Color(0xFFD4D9E4);
  static const cta = Color(0xFF172C57);
  static const chipBorder = Color(0xFFE9EDF4);
}
