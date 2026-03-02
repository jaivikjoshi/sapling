import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/sapling_colors.dart';
import '../../../domain/models/enums.dart';
import '../onboarding_controller.dart';

class IncomeFormSheet extends StatefulWidget {
  const IncomeFormSheet({super.key, required this.onSave});

  final ValueChanged<OnboardingIncomeData> onSave;

  @override
  State<IncomeFormSheet> createState() => _IncomeFormSheetState();
}

class _IncomeFormSheetState extends State<IncomeFormSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  IncomeFrequency _frequency = IncomeFrequency.biweekly;
  PaydayBehavior _behavior = PaydayBehavior.confirmActualOnPayday;
  DateTime _nextPayday = DateTime.now().add(const Duration(days: 14));

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _isValid => _nameCtrl.text.trim().isNotEmpty;

  String? get _autoPostError {
    if (_behavior != PaydayBehavior.autoPostExpected) return null;
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      return 'Auto-post requires a positive expected amount.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Income Schedule',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name (e.g. "Day Job")'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<IncomeFrequency>(
              value: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: const [
                DropdownMenuItem(value: IncomeFrequency.weekly, child: Text('Weekly')),
                DropdownMenuItem(value: IncomeFrequency.biweekly, child: Text('Bi-weekly')),
                DropdownMenuItem(value: IncomeFrequency.monthly, child: Text('Monthly')),
              ],
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Next payday'),
                child: Text(
                  '${_nextPayday.month}/${_nextPayday.day}/${_nextPayday.year}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Expected take-home (optional)',
                prefixText: '\$ ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaydayBehavior>(
              value: _behavior,
              decoration: const InputDecoration(labelText: 'Payday behavior'),
              items: const [
                DropdownMenuItem(
                  value: PaydayBehavior.confirmActualOnPayday,
                  child: Text('Confirm actual on payday'),
                ),
                DropdownMenuItem(
                  value: PaydayBehavior.autoPostExpected,
                  child: Text('Auto-post expected amount'),
                ),
              ],
              onChanged: (v) => setState(() => _behavior = v!),
            ),
            if (_autoPostError != null) ...[
              const SizedBox(height: 8),
              Text(_autoPostError!, style: TextStyle(color: SaplingColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isValid && _autoPostError == null ? _save : null,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextPayday,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _nextPayday = picked);
  }

  void _save() {
    widget.onSave(OnboardingIncomeData(
      tempId: OnboardingController.newTempId(),
      name: _nameCtrl.text.trim(),
      frequency: _frequency,
      nextPaydayDate: _nextPayday,
      expectedAmount: double.tryParse(_amountCtrl.text),
      paydayBehavior: _behavior,
    ));
  }
}
