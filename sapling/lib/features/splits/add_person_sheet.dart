import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/split_providers.dart';
import '../../data/db/sapling_database.dart';

class AddPersonSheet extends ConsumerStatefulWidget {
  const AddPersonSheet({super.key});

  @override
  ConsumerState<AddPersonSheet> createState() => _AddPersonSheetState();
}

class _AddPersonSheetState extends ConsumerState<AddPersonSheet> {
  final _nameCtrl = TextEditingController();
  final _handleCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _handleCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _nameCtrl.text.trim().isNotEmpty;

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
          Text(
            'Add person',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Friend\'s name',
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _handleCtrl,
            decoration: const InputDecoration(
              labelText: 'Handle (optional)',
              hintText: '@username',
            ),
            onChanged: (_) => setState(() {}),
          ),
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
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(personsRepositoryProvider);
      final now = DateTime.now();
      final id = const Uuid().v4();
      await repo.insert(PersonsCompanion.insert(
        id: id,
        name: _nameCtrl.text.trim(),
        handle: _handleCtrl.text.trim().isEmpty
            ? const Value.absent()
            : Value(_handleCtrl.text.trim()),
        createdAt: now,
        updatedAt: now,
      ));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
