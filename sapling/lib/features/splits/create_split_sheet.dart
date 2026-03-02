import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/split_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../data/db/sapling_database.dart';
import '../../domain/services/split_service.dart';

class CreateSplitSheet extends ConsumerStatefulWidget {
  const CreateSplitSheet({super.key, required this.persons});
  final List<Person> persons;

  @override
  ConsumerState<CreateSplitSheet> createState() => _CreateSplitSheetState();
}

class _CreateSplitSheetState extends ConsumerState<CreateSplitSheet> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _paidBy = kSplitPaidByYou;
  List<String> _selectedPersonIds = [];
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(_amountCtrl.text);
  bool get _valid =>
      _descCtrl.text.trim().isNotEmpty &&
      (_amount ?? 0) > 0 &&
      _selectedPersonIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New split',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Dinner, groceries…',
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                prefixText: '\$ ',
                labelText: 'Total amount',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _paidByDropdown(),
            const SizedBox(height: 4),
            Text(
              'Who paid sets who owes whom. Amount is split equally between you and the people below.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SaplingColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Who is in this split? (pick at least one)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SaplingColors.textSecondary,
                  ),
            ),
            ...widget.persons.map((p) => CheckboxListTile(
                  value: _selectedPersonIds.contains(p.id),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedPersonIds = [..._selectedPersonIds, p.id];
                      } else {
                        _selectedPersonIds =
                            _selectedPersonIds.where((id) => id != p.id).toList();
                      }
                    });
                  },
                  title: Text(p.name),
                  controlAffinity: ListTileControlAffinity.leading,
                )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _valid && !_saving ? _save : null,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create split'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paidByDropdown() {
    final options = [
      (kSplitPaidByYou, 'You'),
      ...widget.persons.map((p) => (p.id, p.name)),
    ];
    return DropdownButtonFormField<String>(
      value: options.any((o) => o.$1 == _paidBy) ? _paidBy : null,
      decoration: const InputDecoration(labelText: 'Paid by'),
      items: options
          .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
          .toList(),
      onChanged: (v) => setState(() => _paidBy = v ?? kSplitPaidByYou),
    );
  }

  Future<void> _save() async {
    if (_amount == null || _amount! <= 0 || _selectedPersonIds.isEmpty) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(splitServiceProvider);
      // Split total equally between you and the selected people. Who paid determines who owes whom.
      final participants = [kSplitPaidByYou, ..._selectedPersonIds];
      final each = (_amount! / participants.length * 100).round() / 100;
      var remainder = _amount! - (each * participants.length);
      final shares = participants.asMap().entries.map((e) {
        final amt = e.key == 0 ? each + remainder : each;
        return (personId: e.value, shareAmount: amt);
      }).toList();

      await service.createSplit(
        description: _descCtrl.text.trim(),
        totalAmount: _amount!,
        paidBy: _paidBy,
        shares: shares,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
