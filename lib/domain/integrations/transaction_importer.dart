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

  bool get usesTrustedAggregator;

  Future<BankConnectionStatus> connectionStatus();

  Future<BankConnectionIntent> startConnection();
}

abstract interface class NotificationProvider extends TransactionImporter {
  Future<bool> requestPermission();

  Future<bool> hasPermission();
}

abstract interface class ReceiptOcrProvider {
  Future<ReceiptExtractionResult> extract(ReceiptAttachment attachment);
}

abstract interface class VoiceInputProvider {
  Future<VoiceInputResult> listen();
}

class ImportedTransactionDraft {
  const ImportedTransactionDraft({
    required this.sourceId,
    required this.source,
    required this.amount,
    required this.date,
    this.type = ImportedTransactionType.expense,
    this.merchant,
    this.categorySuggestion,
    this.taxAmount,
    this.note,
    this.attachmentId,
    this.reviewStatus = ImportReviewStatus.pending,
    this.confidence,
  });

  final String sourceId;
  final TransactionImportSource source;
  final double amount;
  final DateTime date;
  final ImportedTransactionType type;
  final String? merchant;
  final String? categorySuggestion;
  final double? taxAmount;
  final String? note;
  final String? attachmentId;
  final ImportReviewStatus reviewStatus;
  final double? confidence;

  String get dedupeKey => '${source.name}:$sourceId';

  ImportedTransactionDraft copyWith({
    String? sourceId,
    TransactionImportSource? source,
    double? amount,
    DateTime? date,
    ImportedTransactionType? type,
    String? Function()? merchant,
    String? Function()? categorySuggestion,
    double? Function()? taxAmount,
    String? Function()? note,
    String? Function()? attachmentId,
    ImportReviewStatus? reviewStatus,
    double? Function()? confidence,
  }) {
    return ImportedTransactionDraft(
      sourceId: sourceId ?? this.sourceId,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      merchant: merchant != null ? merchant() : this.merchant,
      categorySuggestion:
          categorySuggestion != null
              ? categorySuggestion()
              : this.categorySuggestion,
      taxAmount: taxAmount != null ? taxAmount() : this.taxAmount,
      note: note != null ? note() : this.note,
      attachmentId: attachmentId != null ? attachmentId() : this.attachmentId,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      confidence: confidence != null ? confidence() : this.confidence,
    );
  }
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

class BankConnectionIntent {
  const BankConnectionIntent({
    required this.providerId,
    required this.displayName,
    required this.consentCopy,
    this.authorizationUrl,
  });

  final String providerId;
  final String displayName;
  final String consentCopy;
  final Uri? authorizationUrl;
}

class ReceiptAttachment {
  const ReceiptAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final List<int> bytes;
}

class ReceiptExtractionResult {
  const ReceiptExtractionResult({
    required this.attachmentId,
    this.amount,
    this.taxAmount,
    this.merchant,
    this.date,
    this.categorySuggestion,
    this.confidence,
  });

  final String attachmentId;
  final double? amount;
  final double? taxAmount;
  final String? merchant;
  final DateTime? date;
  final String? categorySuggestion;
  final double? confidence;

  ImportedTransactionDraft? toDraft() {
    if (amount == null || date == null) return null;
    return ImportedTransactionDraft(
      sourceId: attachmentId,
      source: TransactionImportSource.receiptOcr,
      amount: amount!,
      taxAmount: taxAmount,
      date: date!,
      merchant: merchant,
      categorySuggestion: categorySuggestion,
      attachmentId: attachmentId,
      confidence: confidence,
    );
  }
}

class VoiceInputResult {
  const VoiceInputResult({
    required this.transcript,
    required this.confidence,
    this.permissionDenied = false,
  });

  final String transcript;
  final double confidence;
  final bool permissionDenied;
}

class TransactionReviewQueue {
  const TransactionReviewQueue();

  List<ImportedTransactionDraft> mergeDrafts({
    required List<ImportedTransactionDraft> existing,
    required List<ImportedTransactionDraft> incoming,
  }) {
    final byKey = {for (final draft in existing) draft.dedupeKey: draft};
    for (final draft in incoming) {
      byKey.putIfAbsent(draft.dedupeKey, () => draft);
    }
    return byKey.values.toList(growable: false);
  }

  List<ImportedTransactionDraft> approve(
    List<ImportedTransactionDraft> drafts,
    Set<String> dedupeKeys,
  ) {
    return drafts
        .map(
          (draft) =>
              dedupeKeys.contains(draft.dedupeKey)
                  ? draft.copyWith(reviewStatus: ImportReviewStatus.approved)
                  : draft,
        )
        .toList(growable: false);
  }

  List<ImportedTransactionDraft> reject(
    List<ImportedTransactionDraft> drafts,
    Set<String> dedupeKeys,
  ) {
    return drafts
        .map(
          (draft) =>
              dedupeKeys.contains(draft.dedupeKey)
                  ? draft.copyWith(reviewStatus: ImportReviewStatus.rejected)
                  : draft,
        )
        .toList(growable: false);
  }

  List<ImportedTransactionDraft> approvedOnly(
    List<ImportedTransactionDraft> drafts,
  ) {
    return drafts
        .where((draft) => draft.reviewStatus == ImportReviewStatus.approved)
        .toList(growable: false);
  }
}

enum BankConnectionStatus {
  disconnected,
  connecting,
  connected,
  needsReauth,
  unavailable,
}

enum TransactionImportSource {
  bankAggregator,
  bankNotification,
  receiptOcr,
  voice,
  manual,
}

enum ImportedTransactionType { expense, income }

enum ImportReviewStatus { pending, approved, rejected, imported }

class UnsupportedBankProvider implements BankProvider {
  const UnsupportedBankProvider();

  @override
  String get displayName => 'Bank connection';

  @override
  String get providerId => 'unsupported_bank_provider';

  @override
  bool get usesTrustedAggregator => true;

  @override
  Future<BankConnectionStatus> connectionStatus() async =>
      BankConnectionStatus.unavailable;

  @override
  Future<TransactionImportResult> importApproved(
    List<ImportedTransactionDraft> drafts,
  ) async {
    return const TransactionImportResult(
      createdCount: 0,
      skippedCount: 0,
      message: 'Bank import needs a trusted aggregator before it can run.',
    );
  }

  @override
  Future<List<ImportedTransactionDraft>> preview() async => const [];

  @override
  Future<BankConnectionIntent> startConnection() async {
    return const BankConnectionIntent(
      providerId: 'unsupported_bank_provider',
      displayName: 'Bank connection',
      consentCopy:
          'Bank connections will use a trusted aggregator. Leko will never ask for or store bank credentials directly.',
    );
  }
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

class UnsupportedReceiptOcrProvider implements ReceiptOcrProvider {
  const UnsupportedReceiptOcrProvider();

  @override
  Future<ReceiptExtractionResult> extract(ReceiptAttachment attachment) async {
    return ReceiptExtractionResult(attachmentId: attachment.id);
  }
}

class UnsupportedVoiceInputProvider implements VoiceInputProvider {
  const UnsupportedVoiceInputProvider();

  @override
  Future<VoiceInputResult> listen() async {
    return const VoiceInputResult(
      transcript: '',
      confidence: 0,
      permissionDenied: true,
    );
  }
}
