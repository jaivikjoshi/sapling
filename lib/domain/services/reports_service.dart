import '../../data/db/sapling_database.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../data/repositories/categories_repository.dart';

/// Date bucketing uses local timezone (DateTime without UTC).
class ReportsService {
  final TransactionsRepository _txnRepo;
  final CategoriesRepository _categoriesRepo;

  ReportsService(this._txnRepo, this._categoriesRepo);

  /// Start of month in local time (inclusive). End is start of next month (exclusive).
  static DateTime monthStart(int year, int month) =>
      DateTime(year, month, 1);

  static DateTime monthEnd(int year, int month) =>
      DateTime(year, month + 1, 1);

  static DateTime yearStart(int year) => DateTime(year, 1, 1);
  static DateTime yearEnd(int year) => DateTime(year + 1, 1, 1);

  Future<MonthlySummary> monthlySummary(int year, int month) async {
    final start = monthStart(year, month);
    final end = monthEnd(year, month);
    final txns = await _txnRepo.getByDateRange(start, end);
    return _summarize(txns);
  }

  Future<AnnualSummary> annualSummary(int year) async {
    final start = yearStart(year);
    final end = yearEnd(year);
    final txns = await _txnRepo.getByDateRange(start, end);
    final s = await _summarize(txns);
    return AnnualSummary(
      year: year,
      incomeTotal: s.incomeTotal,
      expenseTotal: s.expenseTotal,
      adjustmentTotal: s.adjustmentTotal,
      net: s.net,
    );
  }

  Future<MonthlySummary> _summarize(List<Transaction> txns) async {
    double income = 0, expense = 0, adjustment = 0;
    for (final t in txns) {
      switch (t.type) {
        case 'income':
          income += t.amount;
          break;
        case 'expense':
          expense += t.amount;
          break;
        case 'adjustment':
          adjustment += t.amount;
          break;
      }
    }
    return MonthlySummary(
      incomeTotal: income,
      expenseTotal: expense,
      adjustmentTotal: adjustment,
      net: income - expense + adjustment,
    );
  }

  Future<MonthlySummary> periodSummary(DateTime start, DateTime end) async {
    final txns = await _txnRepo.getByDateRange(start, end);
    return _summarize(txns);
  }

  Future<List<Transaction>> getTransactionsInPeriod(DateTime start, DateTime end) async {
    return _txnRepo.getByDateRange(start, end);
  }

  /// Per-category expense total for the month. Only expenses with categoryId.
  Future<List<CategoryBreakdownItem>> categoryBreakdown(int year, int month) async {
    final start = monthStart(year, month);
    final end = monthEnd(year, month);
    return categoryBreakdownByPeriod(start, end);
  }

  /// Per-category expense total for a custom period.
  Future<List<CategoryBreakdownItem>> categoryBreakdownByPeriod(DateTime start, DateTime end) async {
    final txns = await _txnRepo.getByDateRange(start, end);
    final byCategory = <String, double>{};
    for (final t in txns) {
      if (t.type != 'expense' || t.categoryId == null) continue;
      byCategory[t.categoryId!] = (byCategory[t.categoryId!] ?? 0) + t.amount;
    }
    final categories = await _categoriesRepo.getAll();
    final nameById = {for (final c in categories) c.id: c.name};
    return byCategory.entries
        .map((e) => CategoryBreakdownItem(
              categoryId: e.key,
              categoryName: nameById[e.key] ?? e.key,
              total: e.value,
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  /// Bills count when paid: expenses with linkedBillId in [start, end).
  Future<BillsPaidInPeriodResult> billsPaidInPeriod(
      DateTime start, DateTime end) async {
    final txns = await _txnRepo.getByDateRange(start, end);
    final paid = txns
        .where((t) => t.type == 'expense' && t.linkedBillId != null)
        .toList();
    final count = paid.length;
    final total = paid.fold<double>(0, (s, t) => s + t.amount);
    return BillsPaidInPeriodResult(count: count, totalAmount: total);
  }
}

class MonthlySummary {
  final double incomeTotal;
  final double expenseTotal;
  final double adjustmentTotal;
  final double net;

  const MonthlySummary({
    required this.incomeTotal,
    required this.expenseTotal,
    required this.adjustmentTotal,
    required this.net,
  });
}

class AnnualSummary {
  final int year;
  final double incomeTotal;
  final double expenseTotal;
  final double adjustmentTotal;
  final double net;

  const AnnualSummary({
    required this.year,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.adjustmentTotal,
    required this.net,
  });
}

class CategoryBreakdownItem {
  final String categoryId;
  final String categoryName;
  final double total;

  const CategoryBreakdownItem({
    required this.categoryId,
    required this.categoryName,
    required this.total,
  });
}

class BillsPaidInPeriodResult {
  final int count;
  final double totalAmount;

  const BillsPaidInPeriodResult({
    required this.count,
    required this.totalAmount,
  });
}
