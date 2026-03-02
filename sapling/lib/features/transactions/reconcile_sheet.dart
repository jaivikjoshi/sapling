import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/ledger_providers.dart';
import '../../core/providers/widget_snapshot_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../core/utils/currency_formatter.dart';

class ReconcileSheet extends ConsumerStatefulWidget {
  const ReconcileSheet({super.key});

  @override
  ConsumerState<ReconcileSheet> createState() => _ReconcileSheetState();
}

class _ReconcileSheetState extends ConsumerState<ReconcileSheet> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(balanceStreamProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reconcile Balance',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          balanceAsync.when(
            data: (balance) => _buildForm(context, balance),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, double currentBalance) {
    final realBalance = double.tryParse(_ctrl.text);
    final adjustment =
        realBalance != null ? realBalance - currentBalance : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('App balance',
                    style: TextStyle(color: SaplingColors.textSecondary)),
                Text(
                  formatCurrency(currentBalance),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Actual bank balance',
            prefixText: '\$ ',
            hintText: '0.00',
          ),
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        if (adjustment != null) ...[
          const SizedBox(height: 12),
          Card(
            color: adjustment >= 0
                ? SaplingColors.labelGreen.withValues(alpha: 0.1)
                : SaplingColors.labelRed.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Adjustment: ${adjustment >= 0 ? "+" : ""}${formatCurrency(adjustment)}',
                style: TextStyle(
                  color: adjustment >= 0
                      ? SaplingColors.labelGreen
                      : SaplingColors.labelRed,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: realBalance != null && !_saving ? () => _save(realBalance) : null,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Reconcile'),
        ),
      ],
    );
  }

  Future<void> _save(double realBalance) async {
    setState(() => _saving = true);
    try {
      await ref.read(ledgerServiceProvider).reconcile(realBalance);
      ref.read(snapshotWriterProvider).writeSnapshot();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
