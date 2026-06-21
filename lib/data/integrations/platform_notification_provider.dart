import 'package:flutter/services.dart';

import '../../domain/integrations/transaction_importer.dart';
import 'http_bank_provider.dart';

class PlatformNotificationProvider implements NotificationProvider {
  const PlatformNotificationProvider({
    MethodChannel channel = const MethodChannel(_channelName),
    this.userId,
  }) : _channel = channel;

  final MethodChannel _channel;
  final String? userId;

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
    final payload = await _channel.invokeMethod<List<Object?>>(
      'preview',
      {'userId': userId},
    );
    if (payload == null) return const [];
    return payload
        .whereType<Map>()
        .map((draft) => ImportedTransactionDraftJson.fromJson(draft))
        .toList(growable: false);
  }

  Future<void> setActiveUserId(String? userId) async {
    await _channel.invokeMethod<void>('setActiveUserId', {'userId': userId});
  }

  Future<void> clearDraftsForUser(String userId) async {
    await _channel.invokeMethod<void>(
      'clearDraftsForUser',
      {'userId': userId},
    );
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
