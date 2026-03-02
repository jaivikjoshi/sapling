import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/split_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/db/sapling_database.dart';
import '../../domain/services/split_service.dart';
import 'settle_split_sheet.dart';

class SplitDetailScreen extends ConsumerWidget {
  const SplitDetailScreen({super.key, required this.splitEntryId});
  final String splitEntryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splitAsync = ref.watch(splitDetailProvider(splitEntryId));
    final personsAsync = ref.watch(personsListProvider);

    return splitAsync.when(
      data: (entry) {
        if (entry == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Split')),
            body: const Center(child: Text('Split not found')),
          );
        }
        return _SplitDetailBody(
          entry: entry,
          persons: personsAsync.valueOrNull ?? [],
          onSettle: () => _showSettle(context, ref),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Split')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Split')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showSettle(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SettleSplitSheet(splitEntryId: splitEntryId),
    );
  }
}

class _SplitDetailBody extends ConsumerWidget {
  const _SplitDetailBody({
    required this.entry,
    required this.persons,
    required this.onSettle,
  });
  final SplitEntry entry;
  final List<Person> persons;
  final VoidCallback onSettle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat.yMMMd();
    final paidByName = entry.paidBy == kSplitPaidByYou
        ? 'You'
        : persons.where((p) => p.id == entry.paidBy).map((p) => p.name).firstOrNull ?? entry.paidBy;

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.description),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (entry.status == 'open')
            TextButton(
              onPressed: onSettle,
              child: const Text('Settle'),
            ),
        ],
      ),
      body: FutureBuilder<List<SplitShare>>(
        future: ref.read(splitServiceProvider).getSharesForSplit(entry.id),
        builder: (context, snapshot) {
          final shares = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.description,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${dateFmt.format(entry.date)} • ${formatCurrency(entry.totalAmount)}',
                        style: TextStyle(color: SaplingColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paid by: $paidByName',
                        style: TextStyle(color: SaplingColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Shares',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: SaplingColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              ...shares.map((s) {
                final name = s.personId == kSplitPaidByYou
                    ? 'You'
                    : persons.where((p) => p.id == s.personId).map((p) => p.name).firstOrNull ?? s.personId;
                return ListTile(
                  title: Text(name),
                  trailing: Text(formatCurrency(s.shareAmount)),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
