import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/split_providers.dart';
import '../../core/theme/leko_colors.dart';

class SettleSplitSheet extends ConsumerStatefulWidget {
  const SettleSplitSheet({super.key, required this.splitEntryId});
  final String splitEntryId;

  @override
  ConsumerState<SettleSplitSheet> createState() => _SettleSplitSheetState();
}

class _SettleSplitSheetState extends ConsumerState<SettleSplitSheet> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mark as settled?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This will mark the split as settled. Balances will update. No bank transaction is created.',
            style: TextStyle(color: LekoColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saving ? null : _settle,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Settle'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _settle() async {
    setState(() => _saving = true);
    try {
      await ref.read(splitServiceProvider).markSettled(widget.splitEntryId);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
