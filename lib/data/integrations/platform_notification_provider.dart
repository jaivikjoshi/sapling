import 'package:flutter/services.dart';

import '../../domain/integrations/bank_notification_classifier.dart';
import '../../domain/integrations/transaction_importer.dart';
import 'http_bank_provider.dart';

class PlatformNotificationProvider implements NotificationProvider {
  const PlatformNotificationProvider({
    MethodChannel channel = const MethodChannel(_channelName),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<bool> hasPermission() async {
    return await _channel.invokeMethod<bool>('hasPermission') ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  @override
  Future<List<ImportedTransactionDraft>> preview() async {
    final payload = await _channel.invokeMethod<List<Object?>>('preview');
    if (payload == null) return const [];
    return payload
        .whereType<Map>()
        .map((draft) => _draftFromPlatformJson(draft))
        .toList(growable: false);
  }

  ImportedTransactionDraft _draftFromPlatformJson(Map<Object?, Object?> json) {
    final draft = ImportedTransactionDraftJson.fromJson(json);
    final rawText = json['rawText']?.toString();
    if (draft.source != TransactionImportSource.bankNotification ||
        rawText == null ||
        rawText.trim().isEmpty) {
      return draft;
    }
    final type =
        BankNotificationClassifier.typeFor(rawText) == 'income'
            ? ImportedTransactionType.income
            : ImportedTransactionType.expense;
    return draft.copyWith(type: type);
  }

  @override
  Future<TransactionImportResult> importApproved(
    List<ImportedTransactionDraft> drafts,
  ) async {
    return TransactionImportResult(
      createdCount: drafts.length,
      skippedCount: 0,
      message:
          'Notification drafts are imported after review into your local ledger.',
    );
  }

  static const _channelName = 'leko/notification_import';
}
