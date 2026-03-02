import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/reports_providers.dart';
import '../../core/theme/sapling_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/services/reports_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  bool _isMonthly = true;
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  List<int> get _yearOptions {
    final y = DateTime.now().year;
    return List.generate(5, (i) => y - i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Monthly')),
              ButtonSegment(value: false, label: Text('Annual')),
            ],
            selected: {_isMonthly},
            onSelectionChanged: (s) => setState(() => _isMonthly = s.first),
          ),
          const SizedBox(height: 16),
          if (_isMonthly) _monthYearPicker(),
          if (!_isMonthly) _yearPicker(),
          const SizedBox(height: 20),
          if (_isMonthly) _monthlyContent(),
          if (!_isMonthly) _annualContent(),
        ],
      ),
    );
  }

  Widget _monthYearPicker() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _month,
            decoration: const InputDecoration(labelText: 'Month'),
            items: List.generate(12, (i) => i + 1).map((m) {
              return DropdownMenuItem(value: m, child: Text(_monthNames[m - 1]));
            }).toList(),
            onChanged: (v) => setState(() => _month = v ?? _month),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _year,
            decoration: const InputDecoration(labelText: 'Year'),
            items: _yearOptions.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
            onChanged: (v) => setState(() => _year = v ?? _year),
          ),
        ),
      ],
    );
  }

  Widget _yearPicker() {
    return DropdownButtonFormField<int>(
      value: _year,
      decoration: const InputDecoration(labelText: 'Year'),
      items: _yearOptions.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
      onChanged: (v) => setState(() => _year = v ?? _year),
    );
  }

  Widget _monthlyContent() {
    final service = ref.watch(reportsServiceProvider);
    return FutureBuilder<Object>(
      key: ValueKey('monthly_${_year}_$_month'),
      future: Future.wait([
        service.monthlySummary(_year, _month),
        service.categoryBreakdown(_year, _month),
        service.billsPaidInPeriod(
          ReportsService.monthStart(_year, _month),
          ReportsService.monthEnd(_year, _month),
        ),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        }
        final results = snapshot.data as List;
        final summary = results[0] as MonthlySummary;
        final breakdown = results[1] as List<CategoryBreakdownItem>;
        final billsPaid = results[2] as BillsPaidInPeriodResult;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryCards(summary: summary, billsPaid: billsPaid),
            const SizedBox(height: 24),
            Text(
              'Spending by category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: SaplingColors.textSecondary),
            ),
            const SizedBox(height: 8),
            if (breakdown.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text('No expenses this month'))
            else ...[
              _CategoryChart(items: breakdown),
              const SizedBox(height: 12),
              _CategoryList(items: breakdown),
            ],
          ],
        );
      },
    );
  }

  Widget _annualContent() {
    final service = ref.watch(reportsServiceProvider);
    return FutureBuilder<Object>(
      key: ValueKey('annual_$_year'),
      future: Future.wait([
        service.annualSummary(_year),
        service.billsPaidInPeriod(
          ReportsService.yearStart(_year),
          ReportsService.yearEnd(_year),
        ),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        }
        final results = snapshot.data as List;
        final summary = results[0] as AnnualSummary;
        final billsPaid = results[1] as BillsPaidInPeriodResult;
        return _SummaryCards(
          summary: MonthlySummary(
            incomeTotal: summary.incomeTotal,
            expenseTotal: summary.expenseTotal,
            adjustmentTotal: summary.adjustmentTotal,
            net: summary.net,
          ),
          billsPaid: billsPaid,
        );
      },
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary, this.billsPaid});
  final MonthlySummary summary;
  final BillsPaidInPeriodResult? billsPaid;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _Card(title: 'Income', amount: summary.incomeTotal, color: SaplingColors.labelGreen)),
            const SizedBox(width: 12),
            Expanded(child: _Card(title: 'Expense', amount: summary.expenseTotal, color: SaplingColors.labelRed)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _Card(title: 'Adjustment', amount: summary.adjustmentTotal, color: SaplingColors.support)),
            const SizedBox(width: 12),
            Expanded(child: _Card(title: 'Net', amount: summary.net, color: SaplingColors.primary)),
          ],
        ),
        if (billsPaid != null && (billsPaid!.count > 0 || billsPaid!.totalAmount > 0)) ...[
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Bills paid'),
              subtitle: Text('${billsPaid!.count} bill(s) • ${formatCurrency(billsPaid!.totalAmount)}'),
            ),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.amount, required this.color});
  final String title;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: SaplingColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              formatCurrency(amount),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.items});
  final List<CategoryBreakdownItem> items;

  @override
  Widget build(BuildContext context) {
    final max = items.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    if (max <= 0) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: items.take(6).map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(e.categoryName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: max > 0 ? (e.total / max).clamp(0.0, 1.0) : 0,
                      backgroundColor: SaplingColors.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(SaplingColors.labelRed),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(formatCurrency(e.total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.items});
  final List<CategoryBreakdownItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final e = items[i];
          return ListTile(
            title: Text(e.categoryName),
            trailing: Text(formatCurrency(e.total), style: const TextStyle(fontWeight: FontWeight.w600)),
          );
        },
      ),
    );
  }
}
