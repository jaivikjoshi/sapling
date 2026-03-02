import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/category_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../data/db/sapling_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/category_service.dart';

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, this.existing});

  final Category? existing;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _nameCtrl;
  late SpendLabel _label;
  String? _error;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _label = widget.existing != null
        ? LabelRules.defaultForCategory(widget.existing!)
        : SpendLabel.green;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEditing ? 'Edit Category' : 'New Category',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: _error,
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 16),
          Text('Default label',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: SaplingColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: SpendLabel.values.map((l) {
              final color = _colorFor(l);
              final selected = _label == l;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(l.name),
                  selected: selected,
                  selectedColor: color.withValues(alpha: 0.2),
                  avatar: Icon(Icons.circle, size: 12, color: color),
                  onSelected: (_) => setState(() => _label = l),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(_isEditing ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  Color _colorFor(SpendLabel l) => switch (l) {
        SpendLabel.green => SaplingColors.labelGreen,
        SpendLabel.orange => SaplingColors.labelOrange,
        SpendLabel.red => SaplingColors.labelRed,
      };

  Future<void> _save() async {
    final service = ref.read(categoryServiceProvider);
    final nameError = await service.validateName(
      _nameCtrl.text,
      excludeId: widget.existing?.id,
    );
    if (nameError != null) {
      setState(() => _error = nameError);
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await service.update(
          id: widget.existing!.id,
          name: _nameCtrl.text,
          defaultLabel: _label,
        );
      } else {
        await service.create(name: _nameCtrl.text, defaultLabel: _label);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
