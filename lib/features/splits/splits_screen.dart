import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/split_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/db/sapling_database.dart';
import '../../domain/services/split_service.dart';
import 'create_split_sheet.dart';
import 'add_person_sheet.dart';

class SplitsScreen extends ConsumerWidget {
  const SplitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openAsync = ref.watch(openSplitsStreamProvider);
    final balancesAsync = ref.watch(splitBalancesProvider);
    final personsAsync = ref.watch(personsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends & Split'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddPerson(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(splitBalancesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          children: [
            _BalancesSection(balancesAsync: balancesAsync, personsAsync: personsAsync),
            const SizedBox(height: 24),
            Text(
              'Open splits',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SaplingColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            openAsync.when(
              data: (splits) => splits.isEmpty
                  ? const _EmptySplits()
                  : _OpenSplitsList(splits: splits),
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Text('Error: $e', style: TextStyle(color: SaplingColors.error)),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'splits_fab',
        onPressed: () => _showCreateSplit(context, ref),
        backgroundColor: SaplingColors.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddPerson(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const AddPersonSheet(),
    );
  }

  void _showCreateSplit(BuildContext context, WidgetRef ref) {
    final persons = ref.read(personsListProvider).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CreateSplitSheet(persons: persons),
    );
  }
}

class _BalancesSection extends StatelessWidget {
  const _BalancesSection({
    required this.balancesAsync,
    required this.personsAsync,
  });

  final AsyncValue<Map<String, PersonBalance>> balancesAsync;
  final AsyncValue<List<Person>> personsAsync;

  @override
  Widget build(BuildContext context) {
    return balancesAsync.when(
      data: (balances) {
        if (balances.isEmpty) {
          return const SizedBox.shrink();
        }
        final names = personsAsync.valueOrNull ?? [];
        final nameMap = {for (final p in names) p.id: p.name};
        final list = balances.values.where((b) => b.personId != kSplitPaidByYou).toList();
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balances',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SaplingColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            ...list.map((b) {
              final name = nameMap[b.personId] ?? b.personId;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(
                    b.owedToYou > 0
                        ? 'Owes you ${formatCurrency(b.owedToYou)}'
                        : 'You owe ${formatCurrency(b.youOwe)}',
                    style: TextStyle(
                      color: b.owedToYou > 0
                          ? SaplingColors.labelGreen
                          : SaplingColors.labelRed,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/splits/person/${b.personId}'),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _OpenSplitsList extends StatelessWidget {
  const _OpenSplitsList({required this.splits});
  final List<SplitEntry> splits;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.MMMd();
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: splits.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = splits[i];
        return ListTile(
          title: Text(s.description),
          subtitle: Text('${dateFmt.format(s.date)} • ${formatCurrency(s.totalAmount)}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/splits/detail/${s.id}'),
        );
      },
    );
  }
}

class _EmptySplits extends StatelessWidget {
  const _EmptySplits();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: SaplingColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'No open splits',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: SaplingColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to create a split',
              style: TextStyle(fontSize: 12, color: SaplingColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
