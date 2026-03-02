import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/category_providers.dart';
import '../../core/providers/ledger_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../data/db/sapling_database.dart';
import 'category_form_sheet.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: catsAsync.when(
        data: (cats) => cats.isEmpty
            ? const Center(child: Text('No categories.'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: cats.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _CategoryTile(
                  category: cats[i],
                  onEdit: () => _showForm(context, ref, existing: cats[i]),
                  onDelete: () => _confirmDelete(context, ref, cats[i]),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, {Category? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryFormSheet(existing: existing),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category cat) {
    if (cat.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('System categories cannot be deleted.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Remove "${cat.name}"? Existing transactions keep their category reference.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(categoryServiceProvider).delete(cat.id);
            },
            child: Text('Delete', style: TextStyle(color: SaplingColors.error)),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _labelColor => switch (category.defaultLabel) {
        'orange' => SaplingColors.labelOrange,
        'red' => SaplingColors.labelRed,
        _ => SaplingColors.labelGreen,
      };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 6,
        backgroundColor: _labelColor,
      ),
      title: Text(
        category.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        category.isSystem ? 'System' : 'Custom',
        style: TextStyle(color: SaplingColors.textSecondary, fontSize: 12),
      ),
      trailing: category.isSystem
          ? null
          : PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
      onTap: category.isSystem ? null : onEdit,
    );
  }
}
