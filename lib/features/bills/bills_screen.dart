import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/bills_providers.dart';
import '../../core/theme/leko_colors.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../domain/models/enums.dart';
import 'bill_form_sheet.dart';
import 'mark_paid_sheet.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Design tokens
// ═══════════════════════════════════════════════════════════════════════════════

class _Tok {
  _Tok._();
  static const double rCard = 24;
  static const double rChip = 12;

  static const bgTop = Color(0xFFF7F6F3);
  static const cardBg = Color(0xFFFCFCFA);

  static const textTitle = Color(0xFF1F2E33);
  static const textPrimary = Color(0xFF24343A);
  static const textSecondary = Color(0xFF7F8E96);
  static const textMuted = Color(0xFFA6B0B5);

  static const borderSubtle = Color(0xFFE7ECE8);
  static const divider = Color(0xFFECE9E4);

  // Status Colors
  static const statusUpcomingBg = Color(0xFFE9EFF1);
  static const statusUpcomingText = Color(0xFF708791);

  static const statusDueSoonBg = Color(0xFFF5E7DB);
  static const statusDueSoonText = Color(0xFFD18A5B);

  static const statusOverdueBg = Color(0xFFF6E0DD);
  static const statusOverdueText = Color(0xFFD96C63);

  // Note: Paid colors kept for future 'Mark Paid' state integration

  static const fabBg = Color(0xFF163C46);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Screen
// ═══════════════════════════════════════════════════════════════════════════════

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsStreamProvider);

    return Scaffold(
      backgroundColor: _Tok.bgTop,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _Tok.textTitle,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Bills',
          style: TextStyle(
            color: _Tok.textTitle,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'bills_fab_premium',
        onPressed: () => _showForm(context),
        backgroundColor: _Tok.fabBg,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: billsAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: _Tok.fabBg),
            ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bills) {
          if (bills.isEmpty) return const _EmptyState();
          return _BillsDashboard(bills: bills);
        },
      ),
    );
  }

  void _showForm(BuildContext context, {Bill? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Tok.bgTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => BillFormSheet(existing: existing),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Dashboard Layout (Summary + List)
// ═══════════════════════════════════════════════════════════════════════════════

class _BillsDashboard extends StatelessWidget {
  const _BillsDashboard({required this.bills});
  final List<Bill> bills;

  @override
  Widget build(BuildContext context) {
    // Computations for the summary card
    final now = DateTime.now();
    final sortedBills = List<Bill>.from(bills)
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    double totalBillsSum = 0;
    DateTime? nextDueDate;

    for (final b in sortedBills) {
      totalBillsSum += b.amount;
      final daysUntil = b.nextDueDate.difference(now).inDays;
      if (daysUntil >= 0) {
        nextDueDate ??= b.nextDueDate;
      }
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: _SummaryCard(
              totalBillsSum: totalBillsSum,
              nextDueDate: nextDueDate,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _BillTilePremium(bill: sortedBills[i]),
              childCount: sortedBills.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Summary Card
// ═══════════════════════════════════════════════════════════════════════════════

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalBillsSum, required this.nextDueDate});

  final double totalBillsSum;
  final DateTime? nextDueDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Tok.cardBg,
        borderRadius: BorderRadius.circular(_Tok.rCard),
        border: Border.all(color: _Tok.borderSubtle, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total bills',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _Tok.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${totalBillsSum.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: _Tok.textTitle,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: LekoColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: LekoColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next due date',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _Tok.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextDueDate != null
                        ? DateFormat('MMM d, yyyy').format(nextDueDate!)
                        : 'None upcoming',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _Tok.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Premium Bill Tile
// ═══════════════════════════════════════════════════════════════════════════════

class _BillTilePremium extends ConsumerWidget {
  const _BillTilePremium({required this.bill});
  final Bill bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freq = enumFromDb<BillFrequency>(
      bill.frequency,
      BillFrequency.values,
    );
    final label = enumFromDb<SpendLabel>(bill.defaultLabel, SpendLabel.values);
    final labelColor = _labelColor(label);
    final dateFmt = DateFormat.MMMd();

    final daysUntil = bill.nextDueDate.difference(DateTime.now()).inDays;

    final bool isDueSoon = daysUntil >= 0 && daysUntil <= 3;

    Color statusBg = _Tok.statusUpcomingBg;
    Color statusText = _Tok.statusUpcomingText;
    String statusStr = 'Upcoming';

    if (daysUntil < 0) {
      statusBg = LekoColors.labelGreen.withValues(alpha: 0.15);
      statusText = LekoColors.labelGreen;
      statusStr = 'Processed';
    } else if (isDueSoon) {
      statusBg = _Tok.statusDueSoonBg;
      statusText = _Tok.statusDueSoonText;
      statusStr = 'Due in $daysUntil d';
      if (daysUntil == 0) statusStr = 'Due today';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _Tok.cardBg,
        borderRadius: BorderRadius.circular(_Tok.rCard),
        border: Border.all(color: _Tok.borderSubtle, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_Tok.rCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(_Tok.rCard),
          onTap: () => _showMarkPaid(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon + Name + Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: labelColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.receipt_rounded,
                        color: labelColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        bill.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _Tok.textTitle,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          color: _Tok.textMuted,
                        ),
                        padding: EdgeInsets.zero,
                        color: _Tok.cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (v) => _onAction(context, ref, v),
                        itemBuilder:
                            (_) => const [
                              PopupMenuItem(
                                value: 'pay',
                                child: Text('Mark Paid'),
                              ),
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: _Tok.statusOverdueText,
                                  ),
                                ),
                              ),
                            ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: _Tok.divider),
                const SizedBox(height: 16),

                // Bottom Row: Details and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Financial / Timing Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '\$${bill.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _Tok.textTitle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•  ${freq.name}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _Tok.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Next: ${dateFmt.format(bill.nextDueDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _Tok.textMuted,
                          ),
                        ),
                      ],
                    ),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(_Tok.rChip),
                      ),
                      child: Text(
                        statusStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'pay':
        _showMarkPaid(context);
        break;
      case 'edit':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: _Tok.bgTop,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          builder: (_) => BillFormSheet(existing: bill),
        );
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
    }
  }

  void _showMarkPaid(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Tok.bgTop,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => MarkPaidSheet(bill: bill),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: _Tok.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Delete Bill',
              style: TextStyle(color: _Tok.textTitle),
            ),
            content: Text(
              'Are you sure you want to delete "${bill.name}"? This cannot be undone.',
              style: const TextStyle(color: _Tok.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: _Tok.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Tok.statusOverdueBg,
                  foregroundColor: _Tok.statusOverdueText,
                  elevation: 0,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(billsServiceProvider).delete(bill.id);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }

  Color _labelColor(SpendLabel label) => switch (label) {
    SpendLabel.green => LekoColors.labelGreen,
    SpendLabel.orange => LekoColors.labelOrange,
    SpendLabel.red => LekoColors.labelRed,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Empty State
// ═══════════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: LekoColors.secondary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: LekoColors.secondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No upcoming bills',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _Tok.textTitle,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track and manage your recurring\nexpenses easily.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: _Tok.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
