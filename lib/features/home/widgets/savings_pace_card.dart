import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/savings_pace_providers.dart';
import '../../../core/theme/leko_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// Wealthsimple-inspired "Savings Pace" hero card that compares the user's
/// actual savings trajectory toward their primary goal against a linear
/// ideal pace. Hides itself entirely when no primary goal exists — falling
/// back to a quiet CTA so the home screen never looks broken.
class SavingsPaceCard extends ConsumerWidget {
  const SavingsPaceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paceAsync = ref.watch(savingsPaceProvider);

    return paceAsync.when(
      loading: () => const _SavingsPaceSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data == null) {
          return _SavingsPaceEmptyCta(onAddGoal: () => context.go('/goals'));
        }
        return _SavingsPaceContent(data: data);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filled state

class _SavingsPaceContent extends StatelessWidget {
  const _SavingsPaceContent({required this.data});

  final SavingsPaceData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progressPct = (data.progress * 100).round();
    final targetLabel = 'Target ${DateFormat.MMMd().format(data.targetDate)}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LekoColors.cardSurfaceSoft,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SAVINGS PACE',
                  style: textTheme.labelSmall?.copyWith(
                    color: LekoColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              _StatusPill(status: data.status),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.goalName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: LekoColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatCurrency(data.savedAmount)} of '
            '${formatCurrency(data.targetAmount)} · $progressPct%',
            style: textTheme.bodyMedium?.copyWith(
              color: LekoColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(height: 150, child: _PaceChart(data: data)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Started ${DateFormat.MMMd().format(data.startDate)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: LekoColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                DateFormat.MMMd().format(data.targetDate),
                style: textTheme.labelSmall?.copyWith(
                  color: LekoColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.insight,
                  style: textTheme.bodyMedium?.copyWith(
                    color: LekoColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                targetLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: LekoColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status pill

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final SavingsStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      SavingsStatus.ahead => (
        LekoColors.pillAheadBg,
        LekoColors.pillAheadFg,
        'Ahead of pace',
      ),
      SavingsStatus.onTrack => (
        LekoColors.pillOnTrackBg,
        LekoColors.pillOnTrackFg,
        'On track',
      ),
      SavingsStatus.behind => (
        LekoColors.pillBehindBg,
        LekoColors.pillBehindFg,
        'Catching up',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart

class _PaceChart extends StatelessWidget {
  const _PaceChart({required this.data});

  final SavingsPaceData data;

  @override
  Widget build(BuildContext context) {
    final span = data.targetDate.difference(data.startDate).inDays.toDouble();
    final maxX = span <= 0 ? 1.0 : span;
    final maxY = data.targetAmount <= 0 ? 1.0 : data.targetAmount;

    final actualSpots = <FlSpot>[
      for (final point in data.history)
        FlSpot(
          point.date.difference(data.startDate).inDays.toDouble(),
          point.amount.clamp(0, maxY),
        ),
    ];

    final idealSpots = <FlSpot>[const FlSpot(0, 0), FlSpot(maxX, maxY)];

    final todayX =
        data.history.isEmpty ? 0.0 : data.history.last.x(start: data.startDate);
    final todayY =
        data.history.isEmpty
            ? 0.0
            : data.history.last.amount.clamp(0, maxY).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY * 1.05,
        clipData: const FlClipData.all(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          // Ideal pace — dotted slate line.
          LineChartBarData(
            spots: idealSpots,
            isCurved: false,
            barWidth: 1.5,
            color: LekoColors.paceIdeal,
            dashArray: const [4, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
          // Actual savings — solid teal line with soft fill.
          LineChartBarData(
            spots: actualSpots,
            isCurved: true,
            curveSmoothness: 0.18,
            preventCurveOverShooting: true,
            barWidth: 2.6,
            color: LekoColors.paceLine,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, _) => spot.x == todayX && spot.y == todayY,
              getDotPainter:
                  (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 5,
                    color: LekoColors.paceLine,
                    strokeColor: LekoColors.cardSurfaceSoft,
                    strokeWidth: 3,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: LekoColors.paceLineSoft,
            ),
          ),
          // Hollow end marker — a 1-point series at the target date.
          LineChartBarData(
            spots: [FlSpot(maxX, maxY)],
            barWidth: 0,
            color: Colors.transparent,
            dotData: FlDotData(
              show: true,
              getDotPainter:
                  (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 5,
                    color: LekoColors.cardSurfaceSoft,
                    strokeColor: LekoColors.paceIdeal,
                    strokeWidth: 1.5,
                  ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

extension on SavingsPoint {
  double x({required DateTime start}) =>
      date.difference(start).inDays.toDouble();
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / empty states

class _SavingsPaceSkeleton extends StatelessWidget {
  const _SavingsPaceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: LekoColors.cardSurfaceSoft,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
    );
  }
}

class _SavingsPaceEmptyCta extends StatelessWidget {
  const _SavingsPaceEmptyCta({required this.onAddGoal});

  final VoidCallback onAddGoal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LekoColors.cardSurfaceSoft,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAVINGS PACE',
            style: textTheme.labelSmall?.copyWith(
              color: LekoColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Set a goal to see your pace',
            style: textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
              color: LekoColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Once you add a goal, this card tracks your savings against an '
            'ideal pace to keep you on target.',
            style: textTheme.bodyMedium?.copyWith(
              color: LekoColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddGoal,
              style: TextButton.styleFrom(
                foregroundColor: LekoColors.paceLine,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: LekoColors.paceIdeal),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Add a goal',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
