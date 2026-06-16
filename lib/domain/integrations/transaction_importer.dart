/// Future-facing contracts for importing transactions from opt-in providers.
///
/// These interfaces intentionally do not include credential handling. Real bank
/// connections should be delegated to a trusted provider SDK or backend flow,
/// and notification reading must only run after explicit platform permission.
abstract interface class TransactionImporter {
  Future<List<ImportedTransactionDraft>> preview();

  Future<TransactionImportResult> importApproved(
    List<ImportedTransactionDraft> drafts,
  );
}

abstract interface class BankProvider extends TransactionImporter {
  String get providerId;

  String get displayName;

  Future<BankConnectionStatus> connectionStatus();
}

abstract interface class NotificationProvider extends TransactionImporter {
  Future<bool> requestPermission();

  Future<bool> hasPermission();
}

class ImportedTransactionDraft {
  const ImportedTransactionDraft({
    required this.sourceId,
    required this.amount,
    required this.date,
    this.merchant,
    this.categorySuggestion,
    this.note,
    this.attachmentId,
  });

  final String sourceId;
  final double amount;
  final DateTime date;
  final String? merchant;
  final String? categorySuggestion;
  final String? note;
  final String? attachmentId;
}

class TransactionImportResult {
  const TransactionImportResult({
    required this.createdCount,
    required this.skippedCount,
    this.message,
  });

  final int createdCount;
  final int skippedCount;
  final String? message;
}

enum BankConnectionStatus {
  disconnected,
  connecting,
  connected,
  needsReauth,
  unavailable,
}

class UnsupportedNotificationProvider implements NotificationProvider {
  const UnsupportedNotificationProvider();

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<TransactionImportResult> importApproved(
    List<ImportedTransactionDraft> drafts,
  ) async {
    return const TransactionImportResult(
      createdCount: 0,
      skippedCount: 0,
      message: 'Notification import is not available on this platform yet.',
    );
  }

  @override
  Future<List<ImportedTransactionDraft>> preview() async => const [];

  @override
  Future<bool> requestPermission() async => false;
}
