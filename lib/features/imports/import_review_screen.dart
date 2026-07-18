import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/integration_providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/integrations/transaction_importer.dart';

class ImportReviewScreen extends ConsumerStatefulWidget {
  const ImportReviewScreen({super.key});

  @override
  ConsumerState<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends ConsumerState<ImportReviewScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          ref
              .read(transactionReviewControllerProvider.notifier)
              .loadBankState(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionReviewControllerProvider);
    final controller = ref.read(transactionReviewControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF24343A)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Transaction review',
          style: TextStyle(
            color: Color(0xFF24343A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
          children: [
            _BankConnectionCard(
              connection: state.connection,
              isLoading: state.isLoading,
              onStartBank: controller.startBankConnection,
              onSelectionChanged: controller.updateSelectedAccounts,
              onDisconnect: controller.disconnectBank,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ImportActionButton(
                    icon: Icons.account_balance_rounded,
                    label: 'Preview bank',
                    onTap:
                        state.isLoading || !state.connection.isConnected
                            ? null
                            : controller.previewBankTransactions,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImportActionButton(
                    icon: Icons.notifications_active_outlined,
                    label: 'Scan alerts',
                    onTap:
                        state.isLoading
                            ? null
                            : controller.previewNotificationTransactions,
                  ),
                ),
              ],
            ),
            if (state.message != null) ...[
              const SizedBox(height: 14),
              _StatusBanner(message: state.message!),
            ],
            const SizedBox(height: 22),
            Text(
              '${state.pending.length} pending • ${state.approved.length} approved',
              style: const TextStyle(
                color: Color(0xFF7D8C94),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (state.drafts.isEmpty)
              const _EmptyReviewCard()
            else
              for (final draft in state.drafts) ...[
                _DraftCard(
                  draft: draft,
                  onApprove: () => controller.approve(draft.dedupeKey),
                  onReject: () => controller.reject(draft.dedupeKey),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed:
                state.approved.isEmpty || state.isLoading
                    ? null
                    : controller.importApproved,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF163C46),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFDCE4E1),
              disabledForegroundColor: const Color(0xFFA8B2AF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child:
                state.isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text(
                      'Import approved',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
          ),
        ),
      ),
    );
  }
}

class _BankConnectionCard extends StatelessWidget {
  const _BankConnectionCard({
    required this.connection,
    required this.isLoading,
    required this.onStartBank,
    required this.onSelectionChanged,
    required this.onDisconnect,
  });

  final BankConnectionDetails connection;
  final bool isLoading;
  final Future<BankConnectionIntent> Function() onStartBank;
  final Future<void> Function(Set<String>) onSelectionChanged;
  final Future<void> Function() onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9EEEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: TextStyle(
              color: Color(0xFF24343A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _description,
            style: TextStyle(
              color: Color(0xFF7D8C94),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          if (connection.accounts.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final account in connection.accounts)
              CheckboxListTile(
                value: account.isSelected,
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: const Color(0xFF2E8F88),
                title: Text(
                  '${account.name}${account.mask == null ? '' : ' ••••${account.mask}'}',
                  style: const TextStyle(
                    color: Color(0xFF24343A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle:
                    account.type == null && account.currency == null
                        ? null
                        : Text(
                          [
                            account.type,
                            account.currency,
                          ].whereType<String>().join(' • '),
                        ),
                onChanged:
                    isLoading
                        ? null
                        : (selected) {
                          final next =
                              connection.accounts
                                  .where(
                                    (item) =>
                                        item.id == account.id
                                            ? selected == true
                                            : item.isSelected,
                                  )
                                  .map((item) => item.id)
                                  .toSet();
                          onSelectionChanged(next);
                        },
              ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (connection.status == BankConnectionStatus.disconnected ||
                  connection.status == BankConnectionStatus.needsReauth)
                OutlinedButton.icon(
                  onPressed: isLoading ? null : () => _connect(context),
                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                  label: Text(
                    connection.status == BankConnectionStatus.needsReauth
                        ? 'Reconnect bank'
                        : 'Connect bank',
                  ),
                ),
              if (connection.isConnected ||
                  connection.status == BankConnectionStatus.needsReauth)
                TextButton.icon(
                  onPressed:
                      isLoading ? null : () => _confirmDisconnect(context),
                  icon: const Icon(Icons.link_off_rounded, size: 18),
                  label: const Text('Disconnect & delete'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String get _title => switch (connection.status) {
    BankConnectionStatus.connected =>
      connection.institutionName ?? 'Bank connected',
    BankConnectionStatus.connecting => 'Finishing bank connection',
    BankConnectionStatus.needsReauth => 'Bank reconnection needed',
    BankConnectionStatus.unavailable => 'Bank connection unavailable',
    BankConnectionStatus.disconnected => 'Connect safely, import deliberately',
  };

  String get _description => switch (connection.status) {
    BankConnectionStatus.connected =>
      'Choose the accounts Leko can sync. Every transaction stays in review until you approve it.${connection.lastSyncAt == null ? '' : ' Last synced ${DateFormat.MMMd().add_jm().format(connection.lastSyncAt!.toLocal())}.'}',
    BankConnectionStatus.connecting =>
      'Your bank is preparing account data. Return here and tap Preview bank in a moment.',
    BankConnectionStatus.needsReauth =>
      'Your bank requires fresh authorization before transactions can sync again.',
    BankConnectionStatus.unavailable =>
      'This build does not have a production bank provider configured.',
    BankConnectionStatus.disconnected =>
      'Leko uses Flinks Connect for bank authorization and never receives your bank username or password. Imported transactions stay as drafts until you approve them.',
  };

  Future<void> _connect(BuildContext context) async {
    try {
      final intent = await onStartBank();
      if (!context.mounted) return;
      final authorizationUrl = intent.authorizationUrl;
      if (authorizationUrl != null) {
        final opened = await launchUrl(
          authorizationUrl,
          mode: LaunchMode.externalApplication,
        );
        if (opened || !context.mounted) return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(intent.consentCopy)));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open bank connection: $error')),
      );
    }
  }

  Future<void> _confirmDisconnect(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Disconnect bank?'),
            content: const Text(
              'Leko will ask Flinks to delete the linked bank data, then remove account metadata and unimported drafts. Transactions you already approved stay in your ledger.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Disconnect & delete'),
              ),
            ],
          ),
    );
    if (confirmed == true) await onDisconnect();
  }
}

class _ImportActionButton extends StatelessWidget {
  const _ImportActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF163C46),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE9EEEB)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.onApprove,
    required this.onReject,
  });

  final ImportedTransactionDraft draft;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final imported = draft.reviewStatus == ImportReviewStatus.imported;
    final rejected = draft.reviewStatus == ImportReviewStatus.rejected;
    final approved = draft.reviewStatus == ImportReviewStatus.approved;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: approved ? const Color(0xFF3B9797) : const Color(0xFFE9EEEB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  draft.merchant ?? _sourceLabel(draft.source),
                  style: const TextStyle(
                    color: Color(0xFF24343A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                formatCurrency(draft.amount),
                style: const TextStyle(
                  color: Color(0xFF24343A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              DateFormat.MMMd().format(draft.date),
              _sourceLabel(draft.source),
              if (draft.accountName != null) draft.accountName!,
            ].join(' • '),
            style: const TextStyle(color: Color(0xFF7D8C94), fontSize: 13),
          ),
          if (draft.categorySuggestion != null) ...[
            const SizedBox(height: 8),
            Text(
              'Suggested category: ${draft.categorySuggestion}',
              style: const TextStyle(
                color: Color(0xFF3B9797),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (draft.pending) ...[
            const SizedBox(height: 8),
            const Text(
              'Pending at your bank • approval unlocks after it posts',
              style: TextStyle(
                color: Color(0xFFB06A35),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _StatusChip(status: draft.reviewStatus),
              const Spacer(),
              if (!imported && !rejected) ...[
                TextButton(onPressed: onReject, child: const Text('Dismiss')),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: approved || draft.pending ? null : onApprove,
                  child: Text(
                    approved
                        ? 'Approved'
                        : draft.pending
                        ? 'Pending'
                        : 'Approve',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ImportReviewStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.name,
        style: const TextStyle(
          color: Color(0xFF2E8F88),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF2E8F88),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _EmptyReviewCard extends StatelessWidget {
  const _EmptyReviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9EEEB)),
      ),
      child: const Text(
        'No drafts yet. Preview a bank connection, scan supported notifications, or send Leaf a receipt/PDF attachment.',
        style: TextStyle(color: Color(0xFF7D8C94), height: 1.45),
      ),
    );
  }
}

String _sourceLabel(TransactionImportSource source) {
  return switch (source) {
    TransactionImportSource.bankAggregator => 'Bank connection',
    TransactionImportSource.bankNotification => 'Bank notification',
    TransactionImportSource.receiptOcr => 'Receipt OCR',
    TransactionImportSource.voice => 'Voice',
    TransactionImportSource.manual => 'Manual',
  };
}
