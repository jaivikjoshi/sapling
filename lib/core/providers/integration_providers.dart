import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/integrations/http_bank_provider.dart';
import '../../data/integrations/platform_notification_provider.dart';
import '../../data/integrations/receipt_ocr_provider_factory.dart';
import '../../data/integrations/speech_voice_input_provider.dart';
import '../../domain/integrations/product_foundations.dart';
import '../../domain/integrations/transaction_importer.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/category_service.dart';
import 'ledger_providers.dart';

final bankProviderProvider = Provider<BankProvider>((ref) {
  const baseUrl = String.fromEnvironment('LEKO_BANK_API_BASE_URL');
  if (baseUrl.trim().isNotEmpty) {
    final client = http.Client();
    ref.onDispose(client.close);
    return HttpBankProvider(
      client: client,
      baseUri: Uri.parse(baseUrl),
      providerIdValue: const String.fromEnvironment(
        'LEKO_BANK_PROVIDER_ID',
        defaultValue: 'trusted_aggregator',
      ),
      displayNameValue: const String.fromEnvironment(
        'LEKO_BANK_PROVIDER_NAME',
        defaultValue: 'Trusted bank connection',
      ),
    );
  }
  return const UnsupportedBankProvider();
});

final notificationImportProvider = Provider<NotificationProvider>((ref) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return const PlatformNotificationProvider();
  }
  return const UnsupportedNotificationProvider();
});

final receiptOcrProvider = Provider<ReceiptOcrProvider>((ref) {
  return createReceiptOcrProvider();
});

final voiceInputProvider = Provider<VoiceInputProvider>((ref) {
  return SpeechVoiceInputProvider();
});

final transactionReviewQueueProvider = Provider<TransactionReviewQueue>((ref) {
  return const TransactionReviewQueue();
});

class TransactionReviewState {
  const TransactionReviewState({
    this.drafts = const [],
    this.isLoading = false,
    this.message,
  });

  final List<ImportedTransactionDraft> drafts;
  final bool isLoading;
  final String? message;

  List<ImportedTransactionDraft> get pending => drafts
      .where((draft) => draft.reviewStatus == ImportReviewStatus.pending)
      .toList(growable: false);

  List<ImportedTransactionDraft> get approved => drafts
      .where((draft) => draft.reviewStatus == ImportReviewStatus.approved)
      .toList(growable: false);

  TransactionReviewState copyWith({
    List<ImportedTransactionDraft>? drafts,
    bool? isLoading,
    String? Function()? message,
  }) {
    return TransactionReviewState(
      drafts: drafts ?? this.drafts,
      isLoading: isLoading ?? this.isLoading,
      message: message != null ? message() : this.message,
    );
  }
}

final transactionReviewControllerProvider =
    StateNotifierProvider<TransactionReviewController, TransactionReviewState>((
      ref,
    ) {
      return TransactionReviewController(ref);
    });

class TransactionReviewController
    extends StateNotifier<TransactionReviewState> {
  TransactionReviewController(this._ref)
    : super(const TransactionReviewState());

  final Ref _ref;
  bool _importInFlight = false;

  Future<BankConnectionIntent> startBankConnection() async {
    return _ref.read(bankProviderProvider).startConnection();
  }

  Future<void> previewBankTransactions() async {
    await _preview(_ref.read(bankProviderProvider));
  }

  Future<void> previewNotificationTransactions() async {
    final provider = _ref.read(notificationImportProvider);
    if (!await provider.hasPermission()) {
      final granted = await provider.requestPermission();
      if (!granted) {
        state = state.copyWith(
          message:
              () =>
                  'Notification import is unavailable or permission was not granted.',
        );
        return;
      }
    }
    await _preview(provider);
  }

  Future<ImportedTransactionDraft?> extractReceiptDraft({
    required String attachmentId,
    required String fileName,
    required String mimeType,
    required String dataBase64,
  }) async {
    late final List<int> bytes;
    try {
      bytes = base64Decode(dataBase64);
    } on FormatException {
      state = state.copyWith(
        message:
            () =>
                'Could not read receipt attachment. The file may be corrupted.',
      );
      return null;
    }
    final result = await _ref
        .read(receiptOcrProvider)
        .extract(
          ReceiptAttachment(
            id: attachmentId,
            fileName: fileName,
            mimeType: mimeType,
            bytes: bytes,
          ),
        );
    final draft = result.toDraft();
    if (draft == null) {
      state = state.copyWith(
        message:
            () =>
                'Receipt parsing is ready for a platform OCR provider, but this file did not produce a complete draft yet.',
      );
      return null;
    }
    addDrafts([draft]);
    return draft;
  }

  void addDrafts(List<ImportedTransactionDraft> drafts) {
    final queue = _ref.read(transactionReviewQueueProvider);
    state = state.copyWith(
      drafts: queue.mergeDrafts(existing: state.drafts, incoming: drafts),
      message:
          () =>
              '${drafts.length} draft${drafts.length == 1 ? '' : 's'} ready for review.',
    );
  }

  void approve(String dedupeKey) {
    final queue = _ref.read(transactionReviewQueueProvider);
    state = state.copyWith(
      drafts: queue.approve(state.drafts, {dedupeKey}),
      message: () => 'Draft approved. Import it when you are ready.',
    );
  }

  void reject(String dedupeKey) {
    final queue = _ref.read(transactionReviewQueueProvider);
    state = state.copyWith(
      drafts: queue.reject(state.drafts, {dedupeKey}),
      message: () => 'Draft dismissed.',
    );
  }

  Future<TransactionImportResult> importApproved() async {
    if (_importInFlight) {
      return const TransactionImportResult(
        createdCount: 0,
        skippedCount: 0,
        message: 'Import already in progress.',
      );
    }
    final approved = _ref
        .read(transactionReviewQueueProvider)
        .approvedOnly(state.drafts);
    if (approved.isEmpty) {
      return const TransactionImportResult(
        createdCount: 0,
        skippedCount: 0,
        message: 'Approve at least one transaction before importing.',
      );
    }

    _importInFlight = true;
    state = state.copyWith(isLoading: true, message: () => null);
    var created = 0;
    var skipped = 0;
    try {
      final ledger = _ref.read(ledgerServiceProvider);
      final transactionsRepo = _ref.read(transactionsRepositoryProvider);
      final existing = await transactionsRepo.getAll();
      final importedTags = <String>{
        for (final txn in existing)
          if (txn.note != null) _importDedupeTagFromNote(txn.note!),
      };
      final categories =
          _ref.read(categoriesProvider).valueOrNull ?? const <Category>[];

      for (final draft in approved) {
        if (draft.amount <= 0) {
          skipped += 1;
          continue;
        }
        final dedupeTag = _importDedupeTag(draft);
        if (importedTags.contains(dedupeTag)) {
          skipped += 1;
          continue;
        }
        if (draft.type == ImportedTransactionType.income) {
          await ledger.addIncome(
            amount: draft.amount,
            date: draft.date,
            postingType: IncomePostingType.manualOneTime,
            source: draft.merchant,
            note: _importNote(draft),
          );
        } else {
          final category = _categoryForDraft(draft, categories);
          await ledger.addExpense(
            amount: draft.amount,
            date: draft.date,
            categoryId: category?.id ?? 'cat_other',
            label:
                category == null
                    ? SpendLabel.green
                    : LabelRules.defaultForCategory(category),
            note: _importNote(draft),
          );
        }
        importedTags.add(dedupeTag);
        created += 1;
      }

      final importedKeys = approved.map((draft) => draft.dedupeKey).toSet();
      state = state.copyWith(
        isLoading: false,
        drafts: state.drafts
            .map(
              (draft) =>
                  importedKeys.contains(draft.dedupeKey)
                      ? draft.copyWith(
                        reviewStatus: ImportReviewStatus.imported,
                      )
                      : draft,
            )
            .toList(growable: false),
        message:
            () => 'Imported $created transaction${created == 1 ? '' : 's'}.',
      );
      return TransactionImportResult(
        createdCount: created,
        skippedCount: skipped,
        message: state.message,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        message: () => 'Import failed: $error',
      );
      return TransactionImportResult(
        createdCount: created,
        skippedCount: skipped,
        message: state.message,
      );
    } finally {
      _importInFlight = false;
    }
  }

  Future<void> _preview(TransactionImporter importer) async {
    state = state.copyWith(isLoading: true, message: () => null);
    try {
      final drafts = await importer.preview();
      addDrafts(drafts);
      state = state.copyWith(isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        message: () => 'Could not preview imported transactions: $error',
      );
    }
  }

  Category? _categoryForDraft(
    ImportedTransactionDraft draft,
    List<Category> categories,
  ) {
    final suggestion = draft.categorySuggestion?.trim().toLowerCase();
    if (suggestion != null && suggestion.isNotEmpty) {
      for (final category in categories) {
        if (category.name.trim().toLowerCase() == suggestion) {
          return category;
        }
      }
    }
    for (final category in categories) {
      if (category.id == 'cat_other' ||
          category.name.trim().toLowerCase() == 'other') {
        return category;
      }
    }
    return categories.isEmpty ? null : categories.first;
  }

  String _importDedupeTag(ImportedTransactionDraft draft) =>
      'Imported from ${enumToDb(draft.source)}:${draft.sourceId}';

  String? _importDedupeTagFromNote(String note) {
    const prefix = 'Imported from ';
    final start = note.indexOf(prefix);
    if (start < 0) return null;
    final tag = note.substring(start).split(' • ').first.trim();
    return tag.isEmpty ? null : tag;
  }

  String _importNote(ImportedTransactionDraft draft) {
    final parts = [
      if (draft.merchant != null && draft.merchant!.trim().isNotEmpty)
        draft.merchant!.trim(),
      if (draft.note != null && draft.note!.trim().isNotEmpty)
        draft.note!.trim(),
      _importDedupeTag(draft),
    ];
    return parts.join(' • ');
  }
}

final localBadgeEngineProvider = Provider<LocalBadgeEngine>((ref) {
  return const LocalBadgeEngine();
});

final savingsGrowthSeriesBuilderProvider = Provider<SavingsGrowthSeriesBuilder>(
  (ref) {
    return const SavingsGrowthSeriesBuilder();
  },
);
