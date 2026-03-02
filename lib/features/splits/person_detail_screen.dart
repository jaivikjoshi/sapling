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

class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({super.key, required this.personId});
  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personsAsync = ref.watch(personsListProvider);
    final balancesAsync = ref.watch(splitBalancesProvider);
    final splitsAsync = ref.watch(openSplitsForPersonProvider(personId));

    final persons = personsAsync.valueOrNull ?? [];
    final name = persons.any((p) => p.id == personId)
        ? persons.firstWhere((p) => p.id == personId).name
        : personId;

    final balance = balancesAsync.valueOrNull?[personId];
    final splits = splitsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: balance == null && !balancesAsync.hasValue
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (balance != null) _BalanceCard(balance: balance, name: name),
                if (balance != null) const SizedBox(height: 24),
                Text(
                  'Open splits with $name',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: SaplingColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                _OpenSplitsForPerson(
                  personId: personId,
                  splits: splits,
                ),
              ],
            ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.name});
  final PersonBalance balance;
  final String name;

  @override
  Widget build(BuildContext context) {
    final owedToYou = balance.owedToYou;
    final youOwe = balance.youOwe;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (owedToYou > 0)
              Row(
                children: [
                  Icon(Icons.arrow_downward, color: SaplingColors.labelGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Owed to you: ${formatCurrency(owedToYou)}',
                    style: TextStyle(
                      color: SaplingColors.labelGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (youOwe > 0) ...[
              if (owedToYou > 0) const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.arrow_upward, color: SaplingColors.labelRed, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'You owe: ${formatCurrency(youOwe)}',
                    style: TextStyle(
                      color: SaplingColors.labelRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (owedToYou == 0 && youOwe == 0)
              Text(
                'No open balance with $name',
                style: TextStyle(color: SaplingColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _OpenSplitsForPerson extends ConsumerWidget {
  const _OpenSplitsForPerson({
    required this.personId,
    required this.splits,
  });
  final String personId;
  final List<SplitEntry> splits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (splits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No open splits',
          style: TextStyle(color: SaplingColors.textSecondary),
        ),
      );
    }
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
          trailing: TextButton(
            onPressed: () => _showSettle(context, ref, s.id),
            child: const Text('Settle'),
          ),
          onTap: () => context.push('/splits/detail/${s.id}'),
        );
      },
    );
  }

  void _showSettle(BuildContext context, WidgetRef ref, String splitId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SettleSplitSheet(splitEntryId: splitId),
    );
  }
}
