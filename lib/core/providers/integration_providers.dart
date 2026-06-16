import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/integrations/product_foundations.dart';
import '../../domain/integrations/transaction_importer.dart';

final bankProviderProvider = Provider<BankProvider>((ref) {
  return const UnsupportedBankProvider();
});

final notificationImportProvider = Provider<NotificationProvider>((ref) {
  return const UnsupportedNotificationProvider();
});

final receiptOcrProvider = Provider<ReceiptOcrProvider>((ref) {
  return const UnsupportedReceiptOcrProvider();
});

final voiceInputProvider = Provider<VoiceInputProvider>((ref) {
  return const UnsupportedVoiceInputProvider();
});

final transactionReviewQueueProvider = Provider<TransactionReviewQueue>((ref) {
  return const TransactionReviewQueue();
});

final localBadgeEngineProvider = Provider<LocalBadgeEngine>((ref) {
  return const LocalBadgeEngine();
});

final savingsGrowthSeriesBuilderProvider = Provider<SavingsGrowthSeriesBuilder>(
  (ref) {
    return const SavingsGrowthSeriesBuilder();
  },
);
