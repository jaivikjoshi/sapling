import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/providers/reports_providers.dart';
import '../../core/theme/leko_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/services/reports_service.dart';
import '../../data/db/leko_database.dart' show Transaction;

class CyclePeriod {
  final DateTime start;
  final DateTime end; // exclusive
  final String label;

  CyclePeriod(this.start, this.end, this.label);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CyclePeriod && start == other.start && end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isBiweekly = true;
  late CyclePeriod _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = _generateCurrentCycle(true);
  }

  CyclePeriod _generateCurrentCycle(bool biweekly) {
    final now = DateTime.now();
    if (biweekly) {
      if (now.day <= 14) {
        return CyclePeriod(
            DateTime(now.year, now.month, 1),
            DateTime(now.year, now.month, 15),
            '${DateFormat('MMM').format(now)} 1 – ${DateFormat('MMM').format(now)} 14');
      } else {
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        return CyclePeriod(
            DateTime(now.year, now.month, 15),
            DateTime(now.year, now.month + 1, 1),
            '${DateFormat('MMM').format(now)} 15 – ${DateFormat('MMM').format(now)} $lastDay');
      }
    } else {
      return CyclePeriod(
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 1),
          DateFormat('MMMM yyyy').format(now));
    }
  }

  List<CyclePeriod> _generatePeriods(bool biweekly) {
    final periods = <CyclePeriod>[];
    final now = DateTime.now();
    if (biweekly) {
      for (int i = 0; i < 12; i++) {
        final targetMonth = DateTime(now.year, now.month - i, 1);
        final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
        periods.add(CyclePeriod(
            DateTime(targetMonth.year, targetMonth.month, 15),
            DateTime(targetMonth.year, targetMonth.month + 1, 1),
            '${DateFormat('MMM').format(targetMonth)} 15 – ${DateFormat('MMM').format(targetMonth)} $lastDay'));
        periods.add(CyclePeriod(
            DateTime(targetMonth.year, targetMonth.month, 1),
            DateTime(targetMonth.year, targetMonth.month, 15),
            '${DateFormat('MMM').format(targetMonth)} 1 – ${DateFormat('MMM').format(targetMonth)} 14'));
      }
    } else {
      for (int i = 0; i < 12; i++) {
        final d = DateTime(now.year, now.month - i, 1);
        periods.add(CyclePeriod(
            DateTime(d.year, d.month, 1),
            DateTime(d.year, d.month + 1, 1),
            DateFormat('MMMM yyyy').format(d)));
      }
    }
    return periods;
  }

  void _showPeriodPicker() {
    final periods = _generatePeriods(_isBiweekly);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                const Text('Select Cycle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF222529))),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: periods.length,
                    itemBuilder: (context, index) {
                      final p = periods[index];
                      final isSelected = p == _selectedPeriod;
                      return ListTile(
                        onTap: () {
                          setState(() => _selectedPeriod = p);
                          Navigator.pop(context);
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        title: Text(
                          p.label,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF4A9D9C) : const Color(0xFF222529),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF4A9D9C)) : null,
                        tileColor: isSelected ? const Color(0xFF4A9D9C).withOpacity(0.05) : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // warm off-white
      appBar: AppBar(
        title: const Text('Reports', style: TextStyle(color: Color(0xFF222529), fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSegmentedControl(),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _showPeriodPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selectedPeriod.label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF222529))),
                          const SizedBox(width: 8),
                          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF868E96), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _ReportContent(period: _selectedPeriod),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isBiweekly = true;
                _selectedPeriod = _generateCurrentCycle(true);
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isBiweekly ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isBiweekly ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))] : null,
                ),
                alignment: Alignment.center,
                child: Text('Biweekly', style: TextStyle(fontWeight: _isBiweekly ? FontWeight.w600 : FontWeight.w500, color: _isBiweekly ? const Color(0xFF222529) : const Color(0xFF868E96))),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isBiweekly = false;
                _selectedPeriod = _generateCurrentCycle(false);
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isBiweekly ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isBiweekly ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))] : null,
                ),
                alignment: Alignment.center,
                child: Text('Monthly', style: TextStyle(fontWeight: !_isBiweekly ? FontWeight.w600 : FontWeight.w500, color: !_isBiweekly ? const Color(0xFF222529) : const Color(0xFF868E96))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportContent extends ConsumerWidget {
  final CyclePeriod period;
  const _ReportContent({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(reportsServiceProvider);

    return FutureBuilder<Object>(
      key: ValueKey('${period.start.toIso8601String()}_${period.end.toIso8601String()}'),
      future: Future.wait([
        service.periodSummary(period.start, period.end),
        service.getTransactionsInPeriod(period.start, period.end),
        service.categoryBreakdownByPeriod(period.start, period.end),
        service.billsPaidInPeriod(period.start, period.end),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFF4A9D9C))));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load reports'));
        }

        final data = snapshot.data as List;
        final summary = data[0] as MonthlySummary;
        final txns = data[1] as List<Transaction>;
        final categories = data[2] as List<CategoryBreakdownItem>;
        final bills = data[3] as BillsPaidInPeriodResult;

        return _buildBody(context, summary, txns, categories, bills);
      },
    );
  }

  Widget _buildBody(BuildContext context, MonthlySummary summary, List<Transaction> txns, List<CategoryBreakdownItem> categories, BillsPaidInPeriodResult bills) {
    final safeRemaining = summary.incomeTotal - summary.expenseTotal;
    final isOver = safeRemaining < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spent so far', style: TextStyle(color: Color(0xFF868E96), fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(summary.expenseTotal),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isOver ? const Color(0xFFD96C6C) : const Color(0xFF222529),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(isOver ? 'Over by' : 'Safe remaining', style: const TextStyle(color: Color(0xFF868E96), fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    isOver ? formatCurrency(-safeRemaining) : '+${formatCurrency(safeRemaining)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isOver ? const Color(0xFFD96C6C) : const Color(0xFF4A9D9C),
                    ),
                  ),
                  const SizedBox(height: 4), // alignment tweak
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _PacingChart(period: period, txns: txns, incomeTotal: summary.incomeTotal, expenseTotal: summary.expenseTotal),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SecondaryMetricCard(
                  title: 'Earned this cycle',
                  value: formatCurrency(summary.incomeTotal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryMetricCard(
                  title: 'Income used',
                  value: summary.incomeTotal > 0 ? '${((summary.expenseTotal / summary.incomeTotal) * 100).toStringAsFixed(1)}%' : '0%',
                  valueColor: isOver ? const Color(0xFFD96C6C) : const Color(0xFF222529),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionCards(summary, period),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Text('Top Drivers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF222529))),
            const SizedBox(height: 16),
            _TopDrivers(categories: categories),
            const SizedBox(height: 32),
          ]
        ],
      ),
    );
  }

  Widget _buildActionCards(MonthlySummary summary, CyclePeriod period) {
    final now = DateTime.now();
    final daysTotal = period.end.difference(period.start).inDays;
    int daysLeft = period.end.difference(now).inDays;
    if (daysLeft < 0) daysLeft = 0;
    if (daysLeft > daysTotal) daysLeft = daysTotal;

    final safeRemaining = summary.incomeTotal - summary.expenseTotal;
    final isOver = safeRemaining < 0;

    String dailyRec = '-\$--';
    if (!isOver && daysLeft > 0) {
      dailyRec = formatCurrency(safeRemaining / daysLeft);
    } else if (!isOver && daysLeft == 0) {
      dailyRec = formatCurrency(safeRemaining);
    } else {
      dailyRec = '\$0.00';
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daily allowed', style: TextStyle(color: Color(0xFF868E96), fontSize: 13)),
                const SizedBox(height: 8),
                Text('$dailyRec / day', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF222529))),
                const SizedBox(height: 4),
                Text('$daysLeft days left', style: const TextStyle(color: Color(0xFF868E96), fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current pace', style: TextStyle(color: Color(0xFF868E96), fontSize: 13)),
                const SizedBox(height: 8),
                Text(isOver ? 'Catching up too fast' : 'Looking good', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isOver ? const Color(0xFFD96C6C) : const Color(0xFF4A9D9C))),
                const SizedBox(height: 4),
                Text(isOver ? 'Exceeding income' : 'Safely below curve', style: const TextStyle(color: Color(0xFF868E96), fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _SecondaryMetricCard({required this.title, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF868E96), fontSize: 13)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: valueColor ?? const Color(0xFF222529))),
        ],
      ),
    );
  }
}

class _TopDrivers extends StatelessWidget {
  final List<CategoryBreakdownItem> categories;

  const _TopDrivers({required this.categories});

  @override
  Widget build(BuildContext context) {
    final top = categories.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          for (int i = 0; i < top.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF868E96)))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(top[i].categoryName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF222529)))),
                  Text(formatCurrency(top[i].total), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF222529))),
                ],
              ),
            ),
            if (i < top.length - 1)
              Divider(height: 1, indent: 72, endIndent: 20, color: Colors.grey.shade100),
          ]
        ],
      ),
    );
  }
}

class _PacingChart extends StatelessWidget {
  final CyclePeriod period;
  final List<Transaction> txns;
  final double incomeTotal;
  final double expenseTotal;

  const _PacingChart({required this.period, required this.txns, required this.incomeTotal, required this.expenseTotal});

  @override
  Widget build(BuildContext context) {
    // Determine the x axis domain
    final daysInPeriod = period.end.difference(period.start).inDays;
    
    // Sort transactions
    final sortedTxns = List<Transaction>.from(txns)..sort((a, b) => a.date.compareTo(b.date));

    // Daily buckets
    List<FlSpot> spendSpots = [];
    List<FlSpot> incomeSpots = [];
    
    double cumSpend = 0;
    double cumIncome = 0;
    
    int todayOffset = DateTime.now().difference(period.start).inDays;
    if (todayOffset < 0) todayOffset = -1;
    if (todayOffset > daysInPeriod) todayOffset = daysInPeriod;

    double maxVal = math.max(10.0, math.max(incomeTotal, expenseTotal) * 1.2);

    Set<int> spendDays = {};
    Set<int> incomeDays = {};

    for (int i = 0; i <= daysInPeriod; i++) {
      final currentDay = period.start.add(Duration(days: i));
      
      // sums for this specific day
      double daySpend = 0;
      double dayIncome = 0;
      
      for (final t in sortedTxns) {
        if (t.date.year == currentDay.year && t.date.month == currentDay.month && t.date.day == currentDay.day) {
          if (t.type == 'expense') daySpend += t.amount;
          if (t.type == 'income') dayIncome += t.amount;
        }
      }
      
      if (daySpend > 0) spendDays.add(i);
      if (dayIncome > 0) incomeDays.add(i);

      cumSpend += daySpend;
      cumIncome += dayIncome;
      
      if (i <= todayOffset) {
        spendSpots.add(FlSpot(i.toDouble(), cumSpend));
        incomeSpots.add(FlSpot(i.toDouble(), cumIncome));
      }
    }
    
    // Project income line to the end of the period if it hasn't reached it
    if (todayOffset < daysInPeriod && incomeSpots.isNotEmpty) {
       // Just carry the last income value forward as projected (flat line)
       double lastIncome = incomeSpots.last.y;
       incomeSpots.add(FlSpot(daysInPeriod.toDouble(), lastIncome));
    }


    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: daysInPeriod.toDouble(),
          minY: 0,
          maxY: maxVal,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal / 4 > 0 ? maxVal / 4 : 10,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == daysInPeriod.toDouble() || value == (daysInPeriod / 2).roundToDouble()) {
                     final d = period.start.add(Duration(days: value.toInt()));
                     return Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text(DateFormat('MMM d').format(d), style: const TextStyle(color: Color(0xFF868E96), fontSize: 10)),
                     );
                  }
                  return const SizedBox.shrink();
                },
                interval: 1,
                reservedSize: 22,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF222529),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    formatCurrency(spot.y),
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            // Income Line
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              curveSmoothness: 0.1,
              color: const Color(0xFF4A9D9C), // Muted Teal
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) => incomeDays.contains(spot.x.toInt()),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF4A9D9C).withOpacity(0.05),
              ),
            ),
            // Spend Line
            LineChartBarData(
              spots: spendSpots,
              isCurved: true,
              curveSmoothness: 0.1,
              color: const Color(0xFFD96C6C), // Muted Coral
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) => spendDays.contains(spot.x.toInt()),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFD96C6C).withOpacity(0.05),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
