import 'package:flutter_test/flutter_test.dart';
import 'package:leko/domain/integrations/product_foundations.dart';
import 'package:leko/domain/integrations/transaction_importer.dart';

void main() {
  test('transaction review queue dedupes and approves drafts', () {
    final queue = TransactionReviewQueue();
    final draft = ImportedTransactionDraft(
      sourceId: 'txn_1',
      source: TransactionImportSource.bankAggregator,
      amount: 12.50,
      date: DateTime(2026, 6, 16),
      merchant: 'Cafe',
    );
    final duplicate = draft.copyWith(merchant: () => 'Cafe updated');

    final merged = queue.mergeDrafts(existing: [draft], incoming: [duplicate]);
    final approved = queue.approve(merged, {draft.dedupeKey});

    expect(merged, hasLength(1));
    expect(approved.single.reviewStatus, ImportReviewStatus.approved);
    expect(queue.approvedOnly(approved), hasLength(1));
  });

  test('receipt extraction converts complete OCR result into review draft', () {
    final result = ReceiptExtractionResult(
      attachmentId: 'receipt_1',
      amount: 48.25,
      taxAmount: 5.45,
      merchant: 'Market',
      date: DateTime(2026, 6, 16),
      categorySuggestion: 'Groceries',
      confidence: 0.86,
    );

    final draft = result.toDraft();

    expect(draft, isNotNull);
    expect(draft!.source, TransactionImportSource.receiptOcr);
    expect(draft.taxAmount, 5.45);
    expect(draft.reviewStatus, ImportReviewStatus.pending);
  });

  test('local badge engine awards personal milestones', () {
    final earned = const LocalBadgeEngine().earned(
      const BadgeProgressSnapshot(
        expenseCount: 1,
        goalCount: 1,
        trackingStreakDays: 7,
        underBudgetToday: true,
        savedThisWeek: false,
        billPaidOnTime: true,
      ),
    );

    expect(earned, contains(LocalBadgeId.firstExpenseAdded));
    expect(earned, contains(LocalBadgeId.firstGoalCreated));
    expect(earned, contains(LocalBadgeId.sevenDayTrackingStreak));
    expect(earned, contains(LocalBadgeId.billPaidOnTime));
    expect(earned, isNot(contains(LocalBadgeId.savedThisWeek)));
  });

  test('savings growth builder creates smooth progress series', () {
    final points = const SavingsGrowthSeriesBuilder().build(
      targetAmount: 1000,
      contributions: [
        SavingsContributionPoint(date: DateTime(2026, 6, 9), amount: 125),
        SavingsContributionPoint(date: DateTime(2026, 6, 2), amount: 100),
      ],
    );

    expect(points.first.balance, 100);
    expect(points.last.balance, 225);
    expect(points.last.progress, 0.225);
  });
}
