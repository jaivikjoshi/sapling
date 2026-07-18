import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/integrations/bank_provider_config.dart';
import '../../data/integrations/http_bank_provider.dart';
import '../../data/integrations/platform_notification_provider.dart';
import '../../data/integrations/receipt_ocr_provider_factory.dart';
import '../../data/integrations/speech_voice_input_provider.dart';
import '../../domain/integrations/product_foundations.dart';
import '../../domain/integrations/transaction_importer.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/category_service.dart';
import 'ledger_providers.dart';
import 'auth_providers.dart';

final bankProviderProvider = Provider<BankProvider>((ref) {
  const baseUrl = String.fromEnvironment('LEKO_BANK_API_BASE_URL');
  if (baseUrl.trim().isNotEmpty) {
    final config = BankProviderConfig.fromDartDefines();
    final client = http.Client();
    ref.onDispose(client.close);
    return HttpBankProvider(
      client: client,
      baseUri: Uri.parse(baseUrl),
      providerIdValue: config.providerId,
      displayNameValue: config.displayName,
      fallbackConsentCopy: config.consentCopy,
      accessTokenProvider: () async {
        final client = ref.read(supabaseClientProvider);
        final session = client.auth.currentSession;
        if (session == null) return null;
        if (session.isExpired) {
          final refreshed = await client.auth.refreshSession();
          return refreshed.session?.accessToken;
        }
        return session.accessToken;
      },
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
    this.connection = const BankConnectionDetails(
      status: BankConnectionStatus.disconnected,
    ),
    this.message,
  });

  final List<ImportedTransactionDraft> drafts;
  final bool isLoading;
  final BankConnectionDetails connection;
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
    BankConnectionDetails? connection,
    String? Function()? message,
  }) {
    return TransactionReviewState(
      drafts: drafts ?? this.drafts,
      isLoading: isLoading ?? this.isLoading,
      connection: connection ?? this.connection,
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
  bool _initialized = false;

  void resetForAuthChange() {
    _initialized = false;
    state = const TransactionReviewState();
  }

  Future<void> loadBankState({bool force = false}) async {
    if (_initialized && !force) return;
    _initialized = true;
    state = state.copyWith(isLoading: true, message: () => null);
    try {
      final provider = _ref.read(bankProviderProvider);
      final connection = await provider.connectionDetails();
      var drafts = state.drafts;
      if (connection.isConnected ||
          connection.status == BankConnectionStatus.needsReauth) {
        final saved = await provider.savedDrafts();
        drafts = _ref
            .read(transactionReviewQueueProvider)
            .mergeDrafts(existing: drafts, incoming: saved);
      } else {
        drafts = drafts
            .where(
              (draft) => draft.source != TransactionImportSource.bankAggregator,
            )
            .toList(growable: false);
      }
      state = state.copyWith(
        isLoading: false,
        connection: connection,
        drafts: drafts,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        message: () => 'Could not load your bank connection: $error',
      );
    }
  }

  Future<BankConnectionIntent> startBankConnection() async {
    state = state.copyWith(
      connection: const BankConnectionDetails(
        status: BankConnectionStatus.connecting,
      ),
      message: () => null,
    );
    try {
      return await _ref.read(bankProviderProvider).startConnection();
    } catch (error) {
      state = state.copyWith(
        connection: const BankConnectionDetails(
          status: BankConnectionStatus.disconnected,
        ),
        message: () => 'Could not start bank connection: $error',
      );
      rethrow;
    }
  }

  Future<void> handleBankCallback(Uri uri) async {
    final status = uri.queryParameters['status'];
    final providerMessage = uri.queryParameters['message'];
    await loadBankState(force: true);
    state = state.copyWith(
      message:
          () =>
              providerMessage ??
              switch (status) {
                'connected' => 'Bank connected. Sync to review transactions.',
                'cancelled' => 'Bank connection was cancelled.',
                _ => 'Bank connection could not be completed.',
              },
    );
  }

  Future<void> updateSelectedAccounts(Set<String> accountIds) async {
    if (accountIds.isEmpty) {
      state = state.copyWith(
        message: () => 'Keep at least one account selected.',
      );
      return;
    }
    state = state.copyWith(isLoading: true, message: () => null);
    try {
      final connection = await _ref
          .read(bankProviderProvider)
          .updateSelectedAccounts(accountIds);
      final saved = await _ref.read(bankProviderProvider).savedDrafts();
      final nonBankDrafts = state.drafts
          .where(
            (draft) => draft.source != TransactionImportSource.bankAggregator,
          )
          .toList(growable: false);
      state = state.copyWith(
        isLoading: false,
        connection: connection,
        drafts: [...nonBankDrafts, ...saved],
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        message: () => 'Could not update bank accounts: $error',
      );
    }
  }

  Future<void> disconnectBank() async {
    state = state.copyWith(isLoading: true, message: () => null);
    try {
      await _ref.read(bankProviderProvider).disconnect();
      state = state.copyWith(
        isLoading: false,
        connection: const BankConnectionDetails(
          status: BankConnectionStatus.disconnected,
        ),
        drafts: state.drafts
            .where(
              (draft) => draft.source != TransactionImportSource.bankAggregator,
            )
            .toList(growable: false),
        message: () => 'Bank disconnected and stored bank data deleted.',
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        message: () => 'Could not disconnect your bank: $error',
      );
    }
  }

  Future<void> previewBankTransactions() async {
    await _preview(_ref.read(bankProviderProvider));
    try {
      final connection =
          await _ref.read(bankProviderProvider).connectionDetails();
      state = state.copyWith(connection: connection);
    } catch (_) {
      // The preview result already carries the user-facing sync error.
    }
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
    final bytes = base64Decode(dataBase64);
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

  Future<void> approve(String dedupeKey) async {
    final queue = _ref.read(transactionReviewQueueProvider);
    final original = state.drafts;
    final draft = _draftForKey(original, dedupeKey);
    if (draft?.pending == true) {
      state = state.copyWith(
        message:
            () => 'Pending bank transactions can be reviewed after they post.',
      );
      return;
    }
    state = state.copyWith(
      drafts: queue.approve(state.drafts, {dedupeKey}),
      message: () => 'Draft approved. Import it when you are ready.',
    );
    if (draft?.source == TransactionImportSource.bankAggregator) {
      try {
        await _ref
            .read(bankProviderProvider)
            .recordReviewDecision(draft!.sourceId, ImportReviewStatus.approved);
      } catch (error) {
        state = state.copyWith(
          drafts: original,
          message: () => 'Could not save approval: $error',
        );
      }
    }
  }

  Future<void> reject(String dedupeKey) async {
    final queue = _ref.read(transactionReviewQueueProvider);
    final original = state.drafts;
    final draft = _draftForKey(original, dedupeKey);
    state = state.copyWith(
      drafts: queue.reject(state.drafts, {dedupeKey}),
      message: () => 'Draft dismissed.',
    );
    if (draft?.source == TransactionImportSource.bankAggregator) {
      try {
        await _ref
            .read(bankProviderProvider)
            .recordReviewDecision(draft!.sourceId, ImportReviewStatus.rejected);
      } catch (error) {
        state = state.copyWith(
          drafts: original,
          message: () => 'Could not save dismissal: $error',
        );
      }
    }
  }

  Future<TransactionImportResult> importApproved() async {
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

    state = state.copyWith(isLoading: true, message: () => null);
    var created = 0;
    var skipped = 0;
    try {
      final ledger = _ref.read(ledgerServiceProvider);
      final transactionsRepo = _ref.read(transactionsRepositoryProvider);
      final existing = await transactionsRepo.getAll();
      final existingByImportNote = {
        for (final txn in existing)
          if (txn.note != null) txn.note!: txn.id,
      };
      final importedNotes = existingByImportNote.keys.toSet();
      final categories =
          _ref.read(categoriesProvider).valueOrNull ?? const <Category>[];

      final auditedBankDrafts = <ImportedTransactionDraft>[];
      for (final draft in approved) {
        final importNote = _importNote(draft);
        if (importedNotes.contains(importNote)) {
          skipped += 1;
          final ledgerId = existingByImportNote[importNote];
          if (draft.source == TransactionImportSource.bankAggregator &&
              ledgerId != null) {
            auditedBankDrafts.add(
              draft.copyWith(ledgerTransactionId: () => ledgerId),
            );
          }
          continue;
        }
        late final String ledgerId;
        if (draft.type == ImportedTransactionType.income) {
          ledgerId = await ledger.addIncome(
            amount: draft.amount,
            date: draft.date,
            postingType: IncomePostingType.manualOneTime,
            source: draft.merchant,
            note: importNote,
          );
        } else {
          final category = _categoryForDraft(draft, categories);
          ledgerId = await ledger.addExpense(
            amount: draft.amount,
            date: draft.date,
            categoryId: category?.id ?? 'cat_other',
            label:
                category == null
                    ? SpendLabel.green
                    : LabelRules.defaultForCategory(category),
            note: importNote,
            source: enumToDb(draft.source),
          );
        }
        importedNotes.add(importNote);
        existingByImportNote[importNote] = ledgerId;
        if (draft.source == TransactionImportSource.bankAggregator) {
          auditedBankDrafts.add(
            draft.copyWith(ledgerTransactionId: () => ledgerId),
          );
        }
        created += 1;
      }

      String? auditWarning;
      if (auditedBankDrafts.isNotEmpty) {
        try {
          await _ref
              .read(bankProviderProvider)
              .importApproved(auditedBankDrafts);
        } catch (_) {
          auditWarning = ' Bank sync history will retry on the next review.';
        }
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
            () =>
                'Imported $created transaction${created == 1 ? '' : 's'}${skipped > 0 ? ', skipped $skipped duplicate${skipped == 1 ? '' : 's'}' : ''}.${auditWarning ?? ''}',
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
    }
  }

  Future<void> _preview(TransactionImporter importer) async {
    state = state.copyWith(isLoading: true, message: () => null);
    try {
      final drafts = await importer.preview();
      addDrafts(drafts);
      state = state.copyWith(isLoading: false);
    } catch (error) {
      final message =
          error is BankSyncPendingException
              ? error.message
              : 'Could not preview imported transactions: $error';
      state = state.copyWith(isLoading: false, message: () => message);
    }
  }

  Category? _categoryForDraft(
    ImportedTransactionDraft draft,
    List<Category> categories,
  ) {
    final suggestion =
        const ImportedCategoryNormalizer()
            .canonicalName(draft.categorySuggestion)
            ?.toLowerCase();
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

  String _importNote(ImportedTransactionDraft draft) {
    final parts = [
      if (draft.merchant != null && draft.merchant!.trim().isNotEmpty)
        draft.merchant!.trim(),
      if (draft.note != null && draft.note!.trim().isNotEmpty)
        draft.note!.trim(),
      'Imported from ${enumToDb(draft.source)}:${draft.sourceId}',
    ];
    return parts.join(' • ');
  }

  ImportedTransactionDraft? _draftForKey(
    List<ImportedTransactionDraft> drafts,
    String dedupeKey,
  ) {
    for (final draft in drafts) {
      if (draft.dedupeKey == dedupeKey) return draft;
    }
    return null;
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
