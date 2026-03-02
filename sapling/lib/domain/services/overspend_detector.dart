import '../../data/repositories/transactions_repository.dart';
import '../models/settings_model.dart';
import 'allowance_engine.dart';

class OverspendResult {
  final bool isOverspent;
  final double overspendAmount;
  final double spendToday;
  final double allowanceToday;

  const OverspendResult({
    required this.isOverspent,
    required this.overspendAmount,
    required this.spendToday,
    required this.allowanceToday,
  });

  static const none = OverspendResult(
    isOverspent: false,
    overspendAmount: 0,
    spendToday: 0,
    allowanceToday: 0,
  );
}

class OverspendDetector {
  final AllowanceEngine _engine;
  final TransactionsRepository _txnRepo;

  OverspendDetector(this._engine, this._txnRepo);

  /// PRD 5.12: After saving an expense, compute AllowanceToday and SpendToday.
  /// If SpendToday > AllowanceToday → overspend.
  Future<OverspendResult> detect({
    required UserSettings settings,
  }) async {
    final result = await _engine.computePaycheckMode(settings: settings);
    final spendToday = await _computeSpendToday();
    final allowance = result.allowanceToday;

    if (spendToday > allowance) {
      return OverspendResult(
        isOverspent: true,
        overspendAmount: spendToday - allowance,
        spendToday: spendToday,
        allowanceToday: allowance,
      );
    }

    return OverspendResult(
      isOverspent: false,
      overspendAmount: 0,
      spendToday: spendToday,
      allowanceToday: allowance,
    );
  }

  Future<double> _computeSpendToday() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day + 1);
    final txns = await _txnRepo.getByDateRange(todayStart, todayEnd);

    double spend = 0;
    for (final txn in txns) {
      if (txn.type == 'expense') {
        spend += txn.amount;
      }
    }
    return spend;
  }
}
