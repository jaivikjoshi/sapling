// ignore_for_file: unused_element, unused_element_parameter

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/allowance_providers.dart';
import '../../core/providers/ledger_providers.dart';
import '../../core/providers/reports_providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/db/leko_database.dart';
import '../../domain/integrations/product_foundations.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/reports_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportTimeframe _timeframe = ReportTimeframe.cycle;
  ReportComparisonMode _comparisonMode = ReportComparisonMode.previousPeriod;
  _ReportChartMode _chartMode = _ReportChartMode.spendVsPace;
  String? _selectedPeriodId;

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(reportPeriodOptionsProvider(_timeframe));
    final allowanceMode = ref.watch(effectiveAllowanceModeProvider);

    return Scaffold(
      backgroundColor: _ReportsPalette.background,
      body: SafeArea(
        child: periodsAsync.when(
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: _ReportsPalette.teal),
              ),
          error:
              (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load report periods.\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ReportsPalette.textSecondary,
                    ),
                  ),
                ),
              ),
          data: (periods) {
            if (periods.isEmpty) {
              return const Center(
                child: Text(
                  'No report periods available yet.',
                  style: TextStyle(color: _ReportsPalette.textSecondary),
                ),
              );
            }

            final selectedPeriod = _selectedFrom(periods) ?? periods.first;
            final request = ReportsRequest(
              period: selectedPeriod,
              comparisonMode: _comparisonMode,
              allowanceMode: allowanceMode,
            );
            final snapshotAsync = ref.watch(reportsSnapshotProvider(request));

            return RefreshIndicator(
              color: _ReportsPalette.teal,
              backgroundColor: Colors.white,
              onRefresh: () async {
                ref.invalidate(reportsSnapshotProvider(request));
                await ref.read(reportsSnapshotProvider(request).future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 120),
                children: [
                  _Header(
                    timeframe: _timeframe,
                    comparisonMode: _comparisonMode,
                    period: selectedPeriod,
                    onTimeframeChanged: (value) {
                      setState(() {
                        _timeframe = value;
                        _selectedPeriodId = null;
                      });
                    },
                    onComparisonChanged: (value) {
                      setState(() => _comparisonMode = value);
                    },
                    onPeriodTap:
                        () => _showPeriodPicker(periods, selectedPeriod),
                  ),
                  const SizedBox(height: 20),
                  snapshotAsync.when(
                    loading:
                        () => const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _ReportsPalette.teal,
                            ),
                          ),
                        ),
                    error:
                        (error, _) => _InlineError(
                          message: 'Reports failed to load.',
                          details: error.toString(),
                        ),
                    data:
                        (snapshot) => _ReportContent(
                          snapshot: snapshot,
                          chartMode: _chartMode,
                          onChartModeChanged: (value) {
                            setState(() => _chartMode = value);
                          },
                          onOpenTransactions: (query, title) {
                            _showTransactionsSheet(title: title, query: query);
                          },
                          onOpenBills: () => _showBillsSheet(snapshot.period),
                          onOpenGoalImpact:
                              () => _showGoalImpactSheet(snapshot.goal),
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  ReportPeriodOption? _selectedFrom(List<ReportPeriodOption> periods) {
    if (_selectedPeriodId == null) return null;
    for (final period in periods) {
      if (period.id == _selectedPeriodId) return period;
    }
    return null;
  }

  Future<void> _showPeriodPicker(
    List<ReportPeriodOption> periods,
    ReportPeriodOption selected,
  ) async {
    final choice = await showModalBottomSheet<ReportPeriodOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => _PeriodPickerSheet(
            title: 'Choose ${_timeframeLabel(_timeframe).toLowerCase()}',
            periods: periods,
            selected: selected,
          ),
    );
    if (choice != null) {
      setState(() => _selectedPeriodId = choice.id);
    }
  }

  Future<void> _showTransactionsSheet({
    required String title,
    required ReportDrilldownQuery query,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TransactionsSheet(title: title, query: query),
    );
  }

  Future<void> _showBillsSheet(ReportPeriodOption period) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _BillsSheet(period: period),
    );
  }

  Future<void> _showGoalImpactSheet(ReportGoalSection goal) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _GoalImpactSheet(goal: goal),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({
    required this.snapshot,
    required this.chartMode,
    required this.onChartModeChanged,
    required this.onOpenTransactions,
    required this.onOpenBills,
    required this.onOpenGoalImpact,
  });

  final ReportsSnapshot snapshot;
  final _ReportChartMode chartMode;
  final ValueChanged<_ReportChartMode> onChartModeChanged;
  final void Function(ReportDrilldownQuery query, String title)
  onOpenTransactions;
  final VoidCallback onOpenBills;
  final VoidCallback onOpenGoalImpact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopStatCards(snapshot: snapshot),
        const SizedBox(height: 16),
        _PrototypeChartCard(snapshot: snapshot),
        const SizedBox(height: 16),
        _InsightCard(snapshot: snapshot),
        const SizedBox(height: 16),
        _DynamicInsightsCard(snapshot: snapshot),
        const SizedBox(height: 16),
        _TopCategoriesCard(
          snapshot: snapshot,
          onOpenCategory: (category) {
            onOpenTransactions(
              ReportDrilldownQuery(
                start: snapshot.period.start,
                end: snapshot.period.end,
                expensesOnly: true,
                categoryId: category.categoryId,
              ),
              category.categoryName,
            );
          },
        ),
        const SizedBox(height: 16),
        _BottomStatCards(snapshot: snapshot, onOpenBills: onOpenBills),
      ],
    );
  }
}

class _DynamicInsightsCard extends StatelessWidget {
  const _DynamicInsightsCard({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final insights = snapshot.dynamicInsights;
    if (insights.isEmpty) return const SizedBox.shrink();

    return _PrototypeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dynamic checks',
            style: TextStyle(
              color: _ReportsPalette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          for (final insight in insights) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF6F2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _dynamicInsightIcon(insight.type),
                    color: _ReportsPalette.teal,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: const TextStyle(
                          color: _ReportsPalette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        insight.detail,
                        style: const TextStyle(
                          color: _ReportsPalette.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (insight != insights.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.timeframe,
    required this.comparisonMode,
    required this.period,
    required this.onTimeframeChanged,
    required this.onComparisonChanged,
    required this.onPeriodTap,
  });

  final ReportTimeframe timeframe;
  final ReportComparisonMode comparisonMode;
  final ReportPeriodOption period;
  final ValueChanged<ReportTimeframe> onTimeframeChanged;
  final ValueChanged<ReportComparisonMode> onComparisonChanged;
  final VoidCallback onPeriodTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reports',
                    style: TextStyle(
                      color: _ReportsPalette.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'A clearer picture of where your money is going.',
                    style: TextStyle(
                      color: _ReportsPalette.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _FilterCircleButton(icon: Icons.tune_rounded, onTap: onPeriodTap),
          ],
        ),
        const SizedBox(height: 16),
        _ModeSwitcher(timeframe: timeframe, onChanged: onTimeframeChanged),
      ],
    );
  }
}

class _TopStatCards extends StatelessWidget {
  const _TopStatCards({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final savingsRate =
        snapshot.earnedThisPeriod <= 0
            ? 0
            : (((snapshot.earnedThisPeriod - snapshot.spentThisPeriod) /
                        snapshot.earnedThisPeriod) *
                    100)
                .round();

    return Row(
      children: [
        Expanded(
          child: _SummaryStatCard(
            label: _spentLabel(snapshot.period.timeframe),
            value: formatCurrency(snapshot.spentThisPeriod),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryStatCard(
            label: 'Savings rate',
            value: '$savingsRate%',
          ),
        ),
      ],
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _ReportsPalette.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _ReportsPalette.textPrimary,
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrototypeChartCard extends StatelessWidget {
  const _PrototypeChartCard({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final bars = _prototypeBars(snapshot.chart.spend);
    final comparison = snapshot.hero.comparison;
    final trendColor =
        comparison == null || comparison.expenseDelta <= 0
            ? _ReportsPalette.teal
            : _ReportsPalette.alert;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending overview',
                      style: TextStyle(
                        color: _ReportsPalette.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Compared with last month',
                      style: TextStyle(
                        color: _ReportsPalette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    comparison == null || comparison.expenseDelta <= 0
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    size: 14,
                    color: trendColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _prototypeComparisonText(comparison),
                    style: TextStyle(
                      color: trendColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < bars.length; i++) ...[
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 38,
                        height: bars[i],
                        decoration: BoxDecoration(
                          color:
                              i == bars.length - 2
                                  ? _ReportsPalette.navy
                                  : _ReportsPalette.teal,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              bars.length,
              (index) => Expanded(
                child: Text(
                  'Week ${index + 1}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ReportsPalette.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final comparison = snapshot.hero.comparison;
    final headline =
        comparison == null
            ? _heroInsight(snapshot.hero.status)
            : _insightHeadline(comparison, snapshot.period.timeframe);
    final detail =
        snapshot.goalFundingRoom > 0
            ? 'That alone kept about ${formatCurrency(snapshot.goalFundingRoom)} available for your goal without changing your overall routine much.'
            : 'A calmer pace here makes more room for bills, recovery, and goal progress.';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: _ReportsPalette.navy,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22132440),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.auto_awesome_rounded,
                size: 15,
                color: Color(0xB3FFFFFF),
              ),
              SizedBox(width: 8),
              Text(
                'INSIGHT',
                style: TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            detail,
            style: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({
    required this.snapshot,
    required this.onOpenCategory,
  });

  final ReportsSnapshot snapshot;
  final ValueChanged<ReportCategoryBreakdown> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final categories = snapshot.spending.topCategories;
    if (categories.isEmpty) {
      return const _PrototypeCard(
        child: Text(
          'No category activity yet for this period.',
          style: TextStyle(color: _ReportsPalette.textSecondary, fontSize: 14),
        ),
      );
    }

    return _PrototypeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top categories',
            style: TextStyle(
              color: _ReportsPalette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          for (final category in categories.take(4)) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onOpenCategory(category),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.categoryName,
                              style: const TextStyle(
                                color: _ReportsPalette.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            formatCurrency(category.total),
                            style: const TextStyle(
                              color: _ReportsPalette.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: category.share,
                          minHeight: 8,
                          backgroundColor: _ReportsPalette.line,
                          valueColor: const AlwaysStoppedAnimation(
                            _ReportsPalette.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (category != categories.take(4).last) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _BottomStatCards extends StatelessWidget {
  const _BottomStatCards({required this.snapshot, required this.onOpenBills});

  final ReportsSnapshot snapshot;
  final VoidCallback onOpenBills;

  @override
  Widget build(BuildContext context) {
    final avgWeeklySpend = snapshot.spending.averageDailySpend * 7;
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.calendar_today_rounded,
            label: 'Bills this ${_periodWord(snapshot.period.timeframe)}',
            value: formatCurrency(snapshot.bills.paidBillsTotal),
            onTap: onOpenBills,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.schedule_rounded,
            label: 'Avg weekly spend',
            value: formatCurrency(avgWeeklySpend),
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: _ReportsPalette.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _ReportsPalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: _ReportsPalette.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: content,
      ),
    );
  }
}

class _PrototypeCard extends StatelessWidget {
  const _PrototypeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FilterCircleButton extends StatelessWidget {
  const _FilterCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: _ReportsPalette.textPrimary, size: 20),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final hero = snapshot.hero;
    final isOverspending = hero.status == ReportPaceStatus.overspending;
    final safeTone =
        isOverspending ? _ReportsPalette.alert : _ReportsPalette.tealBright;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: _ReportsPalette.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _ReportsPalette.outlineStrong),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: _ReportsPalette.teal.withValues(alpha: 0.12),
            blurRadius: 34,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(status: hero.status),
              const Spacer(),
              Text(
                _timeframeLabel(snapshot.period.timeframe),
                style: const TextStyle(
                  color: _ReportsPalette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Spent so far',
            style: TextStyle(
              color: _ReportsPalette.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(snapshot.spentThisPeriod),
            style: const TextStyle(
              color: _ReportsPalette.textPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label:
                      hero.safeRemaining < 0
                          ? 'Over safe range'
                          : 'Safe remaining',
                  value:
                      hero.safeRemaining < 0
                          ? formatCurrency(hero.safeRemaining.abs())
                          : formatCurrency(hero.safeRemaining),
                  valueColor: safeTone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Pace delta',
                  value: _signedCurrency(hero.paceDelta),
                  valueColor:
                      hero.paceDelta > 0
                          ? _ReportsPalette.alert
                          : _ReportsPalette.tealBright,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _heroInsight(hero.status),
            style: const TextStyle(
              color: _ReportsPalette.textSoft,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hero.comparison != null) ...[
            const SizedBox(height: 8),
            Text(
              _comparisonLine(hero.comparison!),
              style: const TextStyle(
                color: _ReportsPalette.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.snapshot,
    required this.chartMode,
    required this.onChartModeChanged,
  });

  final ReportsSnapshot snapshot;
  final _ReportChartMode chartMode;
  final ValueChanged<_ReportChartMode> onChartModeChanged;

  @override
  Widget build(BuildContext context) {
    final series = _seriesFor(snapshot.chart, chartMode);
    final bars = <LineChartBarData>[
      _bar(series.primary, _ReportsPalette.tealBright, 3.0),
      _bar(series.secondary, series.secondaryColor, 2.2),
    ];

    return _SectionCard(
      eyebrow: 'Main chart',
      title: 'Spend against the shape of the period',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _ReportChartMode.values
                    .map(
                      (mode) => _OptionChip(
                        label: _chartModeLabel(mode),
                        selected: chartMode == mode,
                        onTap: () => onChartModeChanged(mode),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX:
                    snapshot.chart.xLabels.isEmpty
                        ? 1
                        : snapshot.chart.xLabels.last.x,
                minY: 0,
                maxY: snapshot.chart.maxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: snapshot.chart.maxY / 4,
                  getDrawingHorizontalLine:
                      (_) => FlLine(
                        color: _ReportsPalette.outline.withValues(alpha: 0.55),
                        strokeWidth: 1,
                      ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, _) {
                        for (final label in snapshot.chart.xLabels) {
                          if ((label.x - value).abs() < 0.2) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                label.label,
                                style: const TextStyle(
                                  color: _ReportsPalette.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => _ReportsPalette.surfaceRaised,
                    getTooltipItems: (spots) {
                      return spots
                          .map(
                            (spot) => LineTooltipItem(
                              formatCurrency(spot.y),
                              const TextStyle(
                                color: _ReportsPalette.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                          .toList();
                    },
                  ),
                ),
                lineBarsData: bars,
                betweenBarsData:
                    chartMode == _ReportChartMode.spendVsPace
                        ? [
                          BetweenBarsData(
                            fromIndex: 0,
                            toIndex: 1,
                            color: _ReportsPalette.teal.withValues(alpha: 0.10),
                          ),
                        ]
                        : const [],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _LegendDot(
                color: _ReportsPalette.tealBright,
                label: series.primaryLabel,
              ),
              const SizedBox(width: 14),
              _LegendDot(
                color: series.secondaryColor,
                label: series.secondaryLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _bar(
    List<ReportChartPoint> points,
    Color color,
    double width,
  ) {
    return LineChartBarData(
      spots: points.map((point) => FlSpot(point.x, point.y)).toList(),
      isCurved: true,
      barWidth: width,
      color: color,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricSpec('Earned', formatCurrency(snapshot.earnedThisPeriod)),
      _MetricSpec('Spent', formatCurrency(snapshot.spentThisPeriod)),
      _MetricSpec('Net flow', _signedCurrency(snapshot.netFlow)),
      _MetricSpec(
        'Daily allowed',
        '${formatCurrency(snapshot.dailyAllowed)}/day',
      ),
      _MetricSpec(
        'Current pace',
        '${formatCurrency(snapshot.currentPace)}/day',
      ),
      _MetricSpec('Projected end', formatCurrency(snapshot.projectedEndSpend)),
      _MetricSpec(
        'Banked allowance',
        _signedCurrency(snapshot.bankedAllowance),
      ),
      _MetricSpec('Days left', '${snapshot.daysLeftInPeriod}'),
      _MetricSpec('No-spend days', '${snapshot.noSpendDays}'),
      _MetricSpec('Goal room', formatCurrency(snapshot.goalFundingRoom)),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          items
              .map(
                (item) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 52) / 2,
                  child: _StatCard(item: item),
                ),
              )
              .toList(),
    );
  }
}

class _SpendingBreakdown extends StatelessWidget {
  const _SpendingBreakdown({
    required this.snapshot,
    required this.onOpenCategory,
  });

  final ReportsSnapshot snapshot;
  final ValueChanged<ReportCategoryBreakdown> onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final spending = snapshot.spending;
    if (spending.topCategories.isEmpty) {
      return const _QuietMessage(
        text:
            'No expense activity yet in this period, so there are no spending drivers to rank.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompactStatRow(
          leftLabel: 'Biggest expense',
          leftValue: spending.biggestExpenseTitle,
          rightLabel: 'Average daily spend',
          rightValue: formatCurrency(spending.averageDailySpend),
        ),
        const SizedBox(height: 8),
        _CompactStatRow(
          leftLabel: 'Spending days',
          leftValue: '${spending.spendingDays}',
          rightLabel: 'Top category share',
          rightValue:
              '${(spending.topCategories.first.share * 100).toStringAsFixed(0)}%',
        ),
        const SizedBox(height: 18),
        for (final category in spending.topCategories) ...[
          _CategoryRow(
            category: category,
            onTap: () => onOpenCategory(category),
          ),
          if (category != spending.topCategories.last)
            const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _LabelBreakdown extends StatelessWidget {
  const _LabelBreakdown({required this.snapshot, required this.onOpenLabel});

  final ReportsSnapshot snapshot;
  final ValueChanged<ReportLabelBreakdown> onOpenLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          snapshot.labels.items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LabelRow(item: item, onTap: () => onOpenLabel(item)),
                ),
              )
              .toList(),
    );
  }
}

class _IncomeSection extends StatelessWidget {
  const _IncomeSection({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final income = snapshot.income;
    return Column(
      children: [
        _CompactStatRow(
          leftLabel: 'Recurring income',
          leftValue: formatCurrency(income.recurringIncomeTotal),
          rightLabel: 'One-time income',
          rightValue: formatCurrency(income.oneTimeIncomeTotal),
        ),
        const SizedBox(height: 10),
        _CompactStatRow(
          leftLabel: 'Confirmed actual',
          leftValue: formatCurrency(income.confirmedActualTotal),
          rightLabel: 'Auto-posted expected',
          rightValue: formatCurrency(income.autoPostedExpectedTotal),
        ),
        const SizedBox(height: 10),
        _CompactStatRow(
          leftLabel: 'Payday count',
          leftValue: '${income.paydayCount}',
          rightLabel: 'Expected variance',
          rightValue: _signedCurrency(income.expectedVariance),
        ),
      ],
    );
  }
}

class _BillsSection extends StatelessWidget {
  const _BillsSection({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final bills = snapshot.bills;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompactStatRow(
          leftLabel: 'Paid bills total',
          leftValue: formatCurrency(bills.paidBillsTotal),
          rightLabel: 'Bills paid',
          rightValue: '${bills.paidBillsCount}',
        ),
        const SizedBox(height: 10),
        _CompactStatRow(
          leftLabel: 'Upcoming bill load',
          leftValue: formatCurrency(bills.upcomingBillLoad),
          rightLabel: 'Upcoming bills',
          rightValue: '${bills.upcomingBillsCount}',
        ),
        if (bills.topBillCategories.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'Biggest bill categories',
            style: TextStyle(
              color: _ReportsPalette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in bills.topBillCategories) ...[
            _SimpleAmountRow(label: item.name, amount: item.amount),
            if (item != bills.topBillCategories.last) const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _GoalSection extends StatelessWidget {
  const _GoalSection({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final goal = snapshot.goal;
    if (!goal.hasPrimaryGoal) {
      return _QuietMessage(text: goal.impactLine);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.goalName!,
                style: const TextStyle(
                  color: _ReportsPalette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _GoalStatusPill(status: goal.realismStatus),
          ],
        ),
        const SizedBox(height: 16),
        _CompactStatRow(
          leftLabel: 'Funding room this period',
          leftValue: formatCurrency(goal.fundingRoomThisPeriod),
          rightLabel: 'Remaining to target',
          rightValue: formatCurrency(goal.remainingToGoal),
        ),
        const SizedBox(height: 10),
        _CompactStatRow(
          leftLabel: 'Pace needed',
          leftValue: '${formatCurrency(goal.paceNeededPerDay)}/day',
          rightLabel: 'Goal-aware allowance',
          rightValue: '${formatCurrency(goal.currentGoalAllowance)}/day',
        ),
        if (goal.suggestedTargetDate != null) ...[
          const SizedBox(height: 10),
          _SimpleAmountRow(
            label: 'Suggested target date',
            amountLabel: DateFormat.yMMMd().format(goal.suggestedTargetDate!),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          goal.impactLine,
          style: const TextStyle(
            color: _ReportsPalette.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _AllowanceSection extends StatelessWidget {
  const _AllowanceSection({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final allowance = snapshot.allowance;
    return Column(
      children: [
        _CompactStatRow(
          leftLabel: 'Average daily allowance',
          leftValue: formatCurrency(allowance.currentDailyAllowance),
          rightLabel: 'Average daily actual',
          rightValue: formatCurrency(allowance.averageDailyActualSpend),
        ),
        const SizedBox(height: 10),
        _CompactStatRow(
          leftLabel: 'Days under allowance',
          leftValue: '${allowance.daysUnderAllowance}',
          rightLabel: 'Days over allowance',
          rightValue: '${allowance.daysOverAllowance}',
        ),
        const SizedBox(height: 10),
        _CompactStatRow(
          leftLabel: 'Banked built',
          leftValue: formatCurrency(allowance.bankedBuilt),
          rightLabel: 'Banked used',
          rightValue: formatCurrency(allowance.bankedUsed),
        ),
        const SizedBox(height: 10),
        _CompactStatRow(
          leftLabel: allowance.modeImpactTitle,
          leftValue: '${allowance.modeImpactDays} days left',
          rightLabel: 'Safe remaining',
          rightValue: formatCurrency(allowance.modeImpactRemaining),
        ),
        const SizedBox(height: 12),
        Text(
          allowance.behindAmount > 0
              ? 'You are carrying ${formatCurrency(allowance.behindAmount)} of pace pressure into the next stretch.'
              : 'Current pace still leaves breathing room in the plan.',
          style: const TextStyle(
            color: _ReportsPalette.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _HabitsSection extends StatelessWidget {
  const _HabitsSection({required this.snapshot});

  final ReportsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final habits = snapshot.habits;
    return Column(
      children: [
        _CompactStatRow(
          leftLabel: 'Closeout streak',
          leftValue: '${habits.currentCloseoutStreak} days',
          rightLabel: 'No-spend days',
          rightValue: '${habits.noSpendDays}',
        ),
        const SizedBox(height: 10),
        _CompactStatRow(
          leftLabel: 'Overspend events',
          leftValue: '${habits.overspendEvents}',
          rightLabel: 'Total overspend',
          rightValue: formatCurrency(habits.totalOverspendAmount),
        ),
        const SizedBox(height: 10),
        _CompactStatRow(
          leftLabel: 'Today',
          leftValue: habits.todayWithinBudget ? 'Within budget' : 'Over budget',
          rightLabel: 'Recovery',
          rightValue:
              habits.hasActiveRecoveryPlan
                  ? _signedCurrency(habits.activeRecoveryAdjustment)
                  : 'Inactive',
        ),
        const SizedBox(height: 12),
        Text(
          habits.hasActiveRecoveryPlan
              ? 'An active recovery plan is trimming ${formatCurrency(habits.activeRecoveryAdjustment.abs())} from today.'
              : 'No active recovery plan right now. Overspend recovery is not shaping this period.',
          style: const TextStyle(
            color: _ReportsPalette.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.eyebrow,
    required this.title,
    this.trailing,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ReportsPalette.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _ReportsPalette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: const TextStyle(
                        color: _ReportsPalette.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ReportsPalette.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _TransactionsSheet extends ConsumerWidget {
  const _TransactionsSheet({required this.title, required this.query});

  final String title;
  final ReportDrilldownQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(
      reportDrilldownTransactionsProvider(query),
    );
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final categoryById = {
      for (final category in categories) category.id: category,
    };

    return _SheetFrame(
      title: title,
      child: transactionsAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: _ReportsPalette.teal),
            ),
        error:
            (error, _) => Center(
              child: Text(
                'Failed to load transactions.\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _ReportsPalette.textSecondary),
              ),
            ),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const _QuietMessage(
              text: 'Nothing matched this filter in the selected period.',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder:
                (context, index) => _TransactionRow(
                  transaction: transactions[index],
                  categoryName:
                      transactions[index].categoryId == null
                          ? null
                          : categoryById[transactions[index].categoryId!]?.name,
                ),
          );
        },
      ),
    );
  }
}

class _BillsSheet extends ConsumerWidget {
  const _BillsSheet({required this.period});

  final ReportPeriodOption period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(reportBillRowsProvider(period));
    return _SheetFrame(
      title: 'Paid bills',
      child: billsAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: _ReportsPalette.teal),
            ),
        error:
            (error, _) => Center(
              child: Text(
                'Failed to load bill details.\n$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _ReportsPalette.textSecondary),
              ),
            ),
        data: (rows) {
          if (rows.isEmpty) {
            return const _QuietMessage(
              text: 'No paid bills were posted in this period.',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final row = rows[index];
              return Material(
                color: _ReportsPalette.surfaceRaised,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.pop(context);
                    final state =
                        context.findAncestorStateOfType<_ReportsScreenState>();
                    state?._showTransactionsSheet(
                      title: row.title,
                      query: ReportDrilldownQuery(
                        start: period.start,
                        end: period.end,
                        expensesOnly: true,
                        billOnly: true,
                        linkedBillId: row.id,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.title,
                                style: const TextStyle(
                                  color: _ReportsPalette.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                row.subtitle,
                                style: const TextStyle(
                                  color: _ReportsPalette.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatCurrency(row.amount),
                          style: const TextStyle(
                            color: _ReportsPalette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _GoalImpactSheet extends StatelessWidget {
  const _GoalImpactSheet({required this.goal});

  final ReportGoalSection goal;

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Goal impact',
      child:
          goal.hasPrimaryGoal
              ? ListView(
                padding: EdgeInsets.zero,
                children: [
                  Text(
                    goal.goalName!,
                    style: const TextStyle(
                      color: _ReportsPalette.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    goal.impactLine,
                    style: const TextStyle(
                      color: _ReportsPalette.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SimpleAmountRow(
                    label: 'Funding room this period',
                    amount: goal.fundingRoomThisPeriod,
                  ),
                  const SizedBox(height: 10),
                  _SimpleAmountRow(
                    label: 'Remaining to target',
                    amount: goal.remainingToGoal,
                  ),
                  const SizedBox(height: 10),
                  _SimpleAmountRow(
                    label: 'Pace needed',
                    amountLabel: '${formatCurrency(goal.paceNeededPerDay)}/day',
                  ),
                  if (goal.suggestedTargetDate != null) ...[
                    const SizedBox(height: 10),
                    _SimpleAmountRow(
                      label: 'Suggested target date',
                      amountLabel: DateFormat.yMMMd().format(
                        goal.suggestedTargetDate!,
                      ),
                    ),
                  ],
                ],
              )
              : _QuietMessage(text: goal.impactLine),
    );
  }
}

class _PeriodPickerSheet extends StatelessWidget {
  const _PeriodPickerSheet({
    required this.title,
    required this.periods,
    required this.selected,
  });

  final String title;
  final List<ReportPeriodOption> periods;
  final ReportPeriodOption selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: _ReportsPalette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: _ReportsPalette.textMuted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: _ReportsPalette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Flexible(
              child: ListView.separated(
                itemCount: periods.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final period = periods[index];
                  final isSelected = period.id == selected.id;
                  return Material(
                    color:
                        isSelected
                            ? _ReportsPalette.surfaceRaised
                            : _ReportsPalette.backgroundSoft,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.pop(context, period),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    period.label,
                                    style: const TextStyle(
                                      color: _ReportsPalette.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    period.caption,
                                    style: const TextStyle(
                                      color: _ReportsPalette.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color:
                                  isSelected
                                      ? _ReportsPalette.tealBright
                                      : _ReportsPalette.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: _ReportsPalette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: _ReportsPalette.textMuted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: _ReportsPalette.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _ReportsBackdrop extends StatelessWidget {
  const _ReportsBackdrop();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _ReportsPalette.background,
      child: SizedBox.expand(),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.details});

  final String message;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ReportsPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ReportsPalette.outline),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: const TextStyle(
              color: _ReportsPalette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            details,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ReportsPalette.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.timeframe, required this.onChanged});

  final ReportTimeframe timeframe;
  final ValueChanged<ReportTimeframe> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          ReportTimeframe.values
              .map(
                (value) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onChanged(value),
                      borderRadius: BorderRadius.circular(999),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              value == timeframe
                                  ? _ReportsPalette.navy
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x120F172A),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _timeframeChipLabel(value),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                value == timeframe
                                    ? Colors.white
                                    : _ReportsPalette.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _ComparisonSwitcher extends StatelessWidget {
  const _ComparisonSwitcher({
    required this.comparisonMode,
    required this.onChanged,
  });

  final ReportComparisonMode comparisonMode;
  final ValueChanged<ReportComparisonMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ReportComparisonMode>(
      color: _ReportsPalette.surfaceRaised,
      onSelected: onChanged,
      itemBuilder:
          (context) => const [
            PopupMenuItem(
              value: ReportComparisonMode.previousPeriod,
              child: Text('Vs last period'),
            ),
            PopupMenuItem(
              value: ReportComparisonMode.none,
              child: Text('No comparison'),
            ),
          ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _ReportsPalette.backgroundSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _ReportsPalette.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              comparisonMode == ReportComparisonMode.previousPeriod
                  ? 'Vs last period'
                  : 'No comparison',
              style: const TextStyle(
                color: _ReportsPalette.textSoft,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.tune_rounded,
              size: 16,
              color: _ReportsPalette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ReportsPalette.backgroundSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _ReportsPalette.textSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: _ReportsPalette.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ReportPaceStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.32)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: _statusColor(status),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ReportsPalette.surfaceRaised.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ReportsPalette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _ReportsPalette.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _ReportsPalette.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              selected
                  ? _ReportsPalette.surfaceRaised
                  : _ReportsPalette.backgroundSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected
                    ? _ReportsPalette.outlineStrong
                    : _ReportsPalette.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected
                    ? _ReportsPalette.textPrimary
                    : _ReportsPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ReportsPalette.backgroundSoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: _ReportsPalette.textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _MetricSpec item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ReportsPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ReportsPalette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              color: _ReportsPalette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: const TextStyle(
              color: _ReportsPalette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStatRow extends StatelessWidget {
  const _CompactStatRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _CompactMetric(label: leftLabel, value: leftValue)),
        const SizedBox(width: 12),
        Expanded(child: _CompactMetric(label: rightLabel, value: rightValue)),
      ],
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _ReportsPalette.backgroundSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _ReportsPalette.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _ReportsPalette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.onTap});

  final ReportCategoryBreakdown category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ReportsPalette.backgroundSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.categoryName,
                      style: const TextStyle(
                        color: _ReportsPalette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formatCurrency(category.total),
                    style: const TextStyle(
                      color: _ReportsPalette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: category.share,
                  minHeight: 8,
                  backgroundColor: _ReportsPalette.surfaceRaised,
                  valueColor: const AlwaysStoppedAnimation(
                    _ReportsPalette.tealBright,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${(category.share * 100).toStringAsFixed(0)}% of spend',
                    style: const TextStyle(
                      color: _ReportsPalette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _trendLabel(category),
                    style: TextStyle(
                      color:
                          category.trendAmount > 0
                              ? _ReportsPalette.alertSoft
                              : _ReportsPalette.tealBright,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.item, required this.onTap});

  final ReportLabelBreakdown item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _spendLabelColor(item.label);
    return Material(
      color: _ReportsPalette.backgroundSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _spendLabelName(item.label),
                  style: const TextStyle(
                    color: _ReportsPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatCurrency(item.total),
                style: const TextStyle(
                  color: _ReportsPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(item.share * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: _ReportsPalette.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalStatusPill extends StatelessWidget {
  const _GoalStatusPill({required this.status});

  final ReportGoalStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _goalStatusColor(status).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _goalStatusLabel(status),
        style: TextStyle(
          color: _goalStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SimpleAmountRow extends StatelessWidget {
  const _SimpleAmountRow({required this.label, this.amount, this.amountLabel})
    : assert(amount != null || amountLabel != null);

  final String label;
  final double? amount;
  final String? amountLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _ReportsPalette.textSecondary),
          ),
        ),
        Text(
          amountLabel ?? formatCurrency(amount!),
          style: const TextStyle(
            color: _ReportsPalette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.categoryName,
  });

  final Transaction transaction;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final amountColor =
        isExpense
            ? _ReportsPalette.alertSoft
            : transaction.type == 'income'
            ? _ReportsPalette.tealBright
            : _ReportsPalette.textPrimary;

    final title =
        transaction.note?.trim().isNotEmpty == true
            ? transaction.note!
            : switch (transaction.type) {
              'expense' => categoryName ?? 'Expense',
              'income' => transaction.source ?? 'Income',
              _ => 'Adjustment',
            };

    final subtitle = [
      DateFormat.MMMd().format(transaction.date),
      if (categoryName != null && transaction.type == 'expense') categoryName!,
      if (transaction.linkedBillId != null) 'Bill payment',
      if (transaction.linkedRecurringIncomeId != null) 'Recurring income',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ReportsPalette.backgroundSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isExpense
                  ? Icons.arrow_downward_rounded
                  : transaction.type == 'income'
                  ? Icons.arrow_upward_rounded
                  : Icons.sync_alt_rounded,
              color: amountColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ReportsPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ReportsPalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isExpense
                ? '-'
                : transaction.amount < 0
                ? ''
                : '+'}${formatCurrency(transaction.amount.abs())}',
            style: TextStyle(color: amountColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _QuietMessage extends StatelessWidget {
  const _QuietMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _ReportsPalette.textSecondary,
        height: 1.45,
      ),
    );
  }
}

class _MetricSpec {
  const _MetricSpec(this.label, this.value);

  final String label;
  final String value;
}

enum _ReportChartMode { spendVsPace, spendVsIncome, projectedEnd }

class _ChartSeriesSelection {
  const _ChartSeriesSelection({
    required this.primary,
    required this.primaryLabel,
    required this.secondary,
    required this.secondaryLabel,
    required this.secondaryColor,
  });

  final List<ReportChartPoint> primary;
  final String primaryLabel;
  final List<ReportChartPoint> secondary;
  final String secondaryLabel;
  final Color secondaryColor;
}

_ChartSeriesSelection _seriesFor(
  ReportChartModel chart,
  _ReportChartMode mode,
) {
  switch (mode) {
    case _ReportChartMode.spendVsIncome:
      return _ChartSeriesSelection(
        primary: chart.spend,
        primaryLabel: 'Spend',
        secondary: chart.income,
        secondaryLabel: 'Income',
        secondaryColor: _ReportsPalette.goldSoft,
      );
    case _ReportChartMode.projectedEnd:
      return _ChartSeriesSelection(
        primary: chart.spend,
        primaryLabel: 'Actual spend',
        secondary: chart.projectedSpend,
        secondaryLabel: 'Projected end',
        secondaryColor: _ReportsPalette.alertSoft,
      );
    case _ReportChartMode.spendVsPace:
      return _ChartSeriesSelection(
        primary: chart.spend,
        primaryLabel: 'Actual spend',
        secondary: chart.pace,
        secondaryLabel: 'Safe pace',
        secondaryColor: _ReportsPalette.textMuted,
      );
  }
}

String _signedCurrency(double value) {
  if (value == 0) return formatCurrency(0);
  final sign = value > 0 ? '+' : '-';
  return '$sign${formatCurrency(value.abs())}';
}

String _heroInsight(ReportPaceStatus status) => switch (status) {
  ReportPaceStatus.underPace =>
    'You are under pace and still spending inside the safer part of the period.',
  ReportPaceStatus.closeToLimit =>
    'You are close to the line. Keep the next few days tighter.',
  ReportPaceStatus.overspending =>
    'You are currently overspending and the period needs recovery.',
};

String _comparisonLine(ReportComparisonSummary comparison) {
  final direction = comparison.expenseDelta <= 0 ? 'less' : 'more';
  final percent =
      comparison.expenseChangePercent == null
          ? ''
          : ' (${comparison.expenseChangePercent!.abs().toStringAsFixed(0)}%)';
  return '${formatCurrency(comparison.expenseDelta.abs())} $direction spent than ${comparison.previousLabel}$percent';
}

List<double> _prototypeBars(List<ReportChartPoint> points) {
  if (points.isEmpty) return const [42, 56, 64, 52];
  final bucketCount = math.min(4, math.max(1, points.length));
  final buckets = List<double>.filled(bucketCount, 0);
  final counts = List<int>.filled(bucketCount, 0);
  for (var i = 0; i < points.length; i++) {
    final bucket = (i * bucketCount / points.length).floor().clamp(
      0,
      bucketCount - 1,
    );
    buckets[bucket] += points[i].y;
    counts[bucket] += 1;
  }
  for (var i = 0; i < bucketCount; i++) {
    if (counts[i] > 0) buckets[i] = buckets[i] / counts[i];
  }
  final maxValue = buckets.fold<double>(0, math.max);
  if (maxValue <= 0) return List<double>.filled(bucketCount, 44);
  return buckets
      .map((value) => 44 + ((value / maxValue) * 92))
      .toList(growable: false);
}

String _prototypeComparisonText(ReportComparisonSummary? comparison) {
  if (comparison?.expenseChangePercent == null) return 'No comparison';
  final pct = comparison!.expenseChangePercent!.abs().round();
  final word = comparison.expenseDelta <= 0 ? 'lower' : 'higher';
  return '$pct% $word';
}

String _insightHeadline(
  ReportComparisonSummary comparison,
  ReportTimeframe timeframe,
) {
  final percent = comparison.expenseChangePercent?.abs().round();
  final direction = comparison.expenseDelta <= 0 ? 'less' : 'more';
  final periodWord = _periodWord(timeframe);
  if (percent == null) {
    return 'You spent ${formatCurrency(comparison.expenseDelta.abs())} $direction this $periodWord.';
  }
  return 'You spent $percent% $direction this $periodWord.';
}

String _spentLabel(ReportTimeframe timeframe) => switch (timeframe) {
  ReportTimeframe.cycle => 'Spent this cycle',
  ReportTimeframe.month => 'Spent this month',
  ReportTimeframe.year => 'Spent this year',
};

String _periodWord(ReportTimeframe timeframe) => switch (timeframe) {
  ReportTimeframe.cycle => 'cycle',
  ReportTimeframe.month => 'month',
  ReportTimeframe.year => 'year',
};

String _trendLabel(ReportCategoryBreakdown category) {
  if (category.trendAmount == 0) return 'Flat vs prior period';
  final direction = category.trendAmount > 0 ? 'more' : 'less';
  return '${formatCurrency(category.trendAmount.abs())} $direction';
}

String _timeframeLabel(ReportTimeframe timeframe) => switch (timeframe) {
  ReportTimeframe.cycle => 'Cycle',
  ReportTimeframe.month => 'Month',
  ReportTimeframe.year => 'Year',
};

String _timeframeChipLabel(ReportTimeframe timeframe) => switch (timeframe) {
  ReportTimeframe.cycle => 'Week',
  ReportTimeframe.month => 'Month',
  ReportTimeframe.year => 'Year',
};

String _chartModeLabel(_ReportChartMode mode) => switch (mode) {
  _ReportChartMode.spendVsPace => 'Spend vs pace',
  _ReportChartMode.spendVsIncome => 'Spend vs income',
  _ReportChartMode.projectedEnd => 'Projected end',
};

String _statusLabel(ReportPaceStatus status) => switch (status) {
  ReportPaceStatus.underPace => 'Under pace',
  ReportPaceStatus.closeToLimit => 'Close to limit',
  ReportPaceStatus.overspending => 'Overspending',
};

Color _statusColor(ReportPaceStatus status) => switch (status) {
  ReportPaceStatus.underPace => _ReportsPalette.tealBright,
  ReportPaceStatus.closeToLimit => _ReportsPalette.goldSoft,
  ReportPaceStatus.overspending => _ReportsPalette.alertSoft,
};

String _goalStatusLabel(ReportGoalStatus status) => switch (status) {
  ReportGoalStatus.onTrack => 'On track',
  ReportGoalStatus.tight => 'Tight',
  ReportGoalStatus.unrealistic => 'Unrealistic',
  ReportGoalStatus.none => 'No goal',
};

Color _goalStatusColor(ReportGoalStatus status) => switch (status) {
  ReportGoalStatus.onTrack => _ReportsPalette.tealBright,
  ReportGoalStatus.tight => _ReportsPalette.goldSoft,
  ReportGoalStatus.unrealistic => _ReportsPalette.alertSoft,
  ReportGoalStatus.none => _ReportsPalette.textMuted,
};

String _spendLabelName(SpendLabel label) => switch (label) {
  SpendLabel.green => 'Green essential',
  SpendLabel.orange => 'Orange justified',
  SpendLabel.red => 'Red non-essential',
};

Color _spendLabelColor(SpendLabel label) => switch (label) {
  SpendLabel.green => _ReportsPalette.green,
  SpendLabel.orange => _ReportsPalette.goldSoft,
  SpendLabel.red => _ReportsPalette.alertSoft,
};

IconData _dynamicInsightIcon(DynamicReportType type) => switch (type) {
  DynamicReportType.recurringSubscriptionDrift => Icons.subscriptions_outlined,
  DynamicReportType.billVariance => Icons.receipt_long_outlined,
  DynamicReportType.categoryAnomaly => Icons.category_outlined,
  DynamicReportType.weeklyForecast => Icons.view_week_outlined,
  DynamicReportType.monthlyForecast => Icons.calendar_month_outlined,
};

abstract final class _ReportsPalette {
  static const background = Color(0xFFF5F7FB);
  static const backgroundSoft = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFF1F5F9);
  static const outline = Color(0xFFE7ECF4);
  static const outlineStrong = Color(0xFFDDE5F0);
  static const navy = Color(0xFF132440);
  static const teal = Color(0xFF3B9797);
  static const tealBright = Color(0xFF3B9797);
  static const goldSoft = Color(0xFFE2BE86);
  static const alert = Color(0xFFD78377);
  static const alertSoft = Color(0xFFF0A998);
  static const green = Color(0xFF76B791);
  static const textPrimary = Color(0xFF0F172A);
  static const textSoft = Color(0xFF334155);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const line = Color(0xFFE7ECF4);
}
