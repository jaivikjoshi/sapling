import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/ledger_providers.dart';
import '../../core/providers/recovery_providers.dart';
import '../../core/providers/scheduler_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/providers/widget_snapshot_providers.dart';
import '../../core/theme/leko_colors.dart';
import '../../data/db/leko_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/category_service.dart';
import '../recovery/overspend_modal.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Design tokens
// ═══════════════════════════════════════════════════════════════════════════════

class _Tok {
  _Tok._();
  // Radii
  static const double rCard = 24;
  static const double rChip = 18;
  static const double rCta = 22;

  // Colors
  static const bgTop = Color(0xFFF7F6F3); // App background
  static const cardBg = Color(0xFFFCFCFA);

  // Typography
  static const textTitle = Color(0xFF24343A);
  static const textPrimary = Color(0xFF263238);
  static const textSecondary = Color(0xFF8C9AA1);
  static const textPlaceholder = Color(0xFFB5BEC1);

  // Borders & Dividers
  static const borderAmount = Color(0xFFD9E5E1);
  static const borderSubtle = Color(0xFFE9EEEB);
  static const divider = Color(0xFFE9EEEB);

  // Details card icon container
  static const iconContainerBg = Color(0xFFF0F4F3);

  // CTA
  static const ctaEnabled = Color(0xFF163C46);
  static const ctaDisabled = Color(0xFFDCE4E1);
  static const ctaTextEnabled = Color(0xFFFFFFFF);
  static const ctaTextDisabled = Color(0xFFA8B2AF);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Screen
// ═══════════════════════════════════════════════════════════════════════════════

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  Category? _selectedCategory;
  SpendLabel? _labelOverride;
  bool _saving = false;

  SpendLabel get _effectiveLabel {
    if (_labelOverride != null) return _labelOverride!;
    if (_selectedCategory != null) {
      return LabelRules.defaultForCategory(_selectedCategory!);
    }
    return SpendLabel.green;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _amountCtrl.text.isNotEmpty &&
      (double.tryParse(_amountCtrl.text) ?? 0) > 0 &&
      _selectedCategory != null;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: _Tok.bgTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.close_rounded,
            color: _Tok.textTitle,
            size: 24,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Add Expense',
          style: TextStyle(
            color: _Tok.textTitle,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  // ── Section 1: Hero Amount Card ──
                  _AmountHeroCard(
                    controller: _amountCtrl,
                    onChanged: () => setState(() {}),
                  ),

                  const SizedBox(height: 32),

                  // ── Section 2: Details Card ──
                  _SectionCard(
                    children: [
                      // Category
                      categoriesAsync.when(
                        data:
                            (cats) => _CategoryRow(
                              categories: cats,
                              selected: _selectedCategory,
                              onChanged:
                                  (cat) => setState(() {
                                    _selectedCategory = cat;
                                    _labelOverride = null;
                                  }),
                            ),
                        loading:
                            () => const Padding(
                              padding: EdgeInsets.all(16),
                              child: LinearProgressIndicator(),
                            ),
                        error:
                            (e, _) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('Error: $e'),
                            ),
                      ),
                      const _CardDivider(),
                      // Date
                      _DateRow(date: _date, onTap: _pickDate),
                      const _CardDivider(),
                      // Note
                      _NoteRow(controller: _noteCtrl),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Section 3: Label Chips ──
                  _LabelSection(
                    effectiveLabel: _effectiveLabel,
                    isOverridden: _labelOverride != null,
                    onChanged: (l) => setState(() => _labelOverride = l),
                    onReset: () => setState(() => _labelOverride = null),
                  ),

                  const SizedBox(height: 16),
                ]),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 32),
                    // ── CTA ──
                    _SaveButton(
                      isValid: _isValid,
                      isSaving: _saving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 48), // Generous bottom spacing
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final txnId = await ref
          .read(ledgerServiceProvider)
          .addExpense(
            amount: double.parse(_amountCtrl.text),
            date: _date,
            categoryId: _selectedCategory!.id,
            label: _effectiveLabel,
            note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
          );

      if (!mounted) return;
      await _checkOverspend(txnId);
      ref.read(snapshotWriterProvider).writeSnapshot();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _checkOverspend(String txnId) async {
    final settings = ref.read(settingsStreamProvider).valueOrNull;
    if (settings == null) {
      if (mounted) context.pop();
      return;
    }

    final detector = ref.read(overspendDetectorProvider);
    final result = await detector.detect(settings: settings);

    if (!mounted) return;

    if (result.isOverspent) {
      if (settings.overspendEnabled) {
        ref.read(notificationSchedulerProvider).showOverspendNow();
      }
      context.pop();
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder:
            (_) => OverspendModal(result: result, triggerTransactionId: txnId),
      );
    } else {
      context.pop();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Hero Amount Card
// ═══════════════════════════════════════════════════════════════════════════════

class _AmountHeroCard extends StatelessWidget {
  const _AmountHeroCard({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
      decoration: BoxDecoration(
        color: _Tok.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDDE6E3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Tok.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter transaction amount',
            style: TextStyle(
              fontSize: 12,
              color: _Tok.textPlaceholder,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            autofocus: true,
            onChanged: (_) => onChanged(),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2E33),
              letterSpacing: -1.5,
            ),
            decoration: const InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.only(right: 8, bottom: 2),
                child: Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: _Tok.textPlaceholder,
                  ),
                ),
              ),
              prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
              hintText: '0.00',
              hintStyle: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w500,
                color: _Tok.textPlaceholder,
                letterSpacing: -1.5,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Section Card wrapper
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: _Tok.divider),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Category Row
// ═══════════════════════════════════════════════════════════════════════════════

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<Category> categories;
  final Category? selected;
  final ValueChanged<Category> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      onTap: () => _showCategorySheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _Tok.iconContainerBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 18,
                color: LekoColors.secondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _Tok.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected?.name ?? 'Choose a category',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color:
                          selected != null
                              ? _Tok.textPrimary
                              : _Tok.textPlaceholder,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _Tok.textPlaceholder,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _Tok.textPlaceholder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose Category',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _Tok.textTitle,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          [
                            ...categories.where(
                              (c) => c.name.toLowerCase() != 'other',
                            ),
                            ...categories.where(
                              (c) => c.name.toLowerCase() == 'other',
                            ),
                          ].map((c) {
                            final color = _labelColor(c.defaultLabel);
                            final isSelected = selected?.id == c.id;
                            return ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: color,
                                ),
                              ),
                              title: Text(
                                c.name,
                                style: TextStyle(
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                  color: _Tok.textPrimary,
                                ),
                              ),
                              trailing:
                                  isSelected
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: LekoColors.secondary,
                                        size: 22,
                                      )
                                      : null,
                              onTap: () {
                                onChanged(c);
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
              ],
            ),
          ),
    );
  }

  Color _labelColor(String label) => switch (label) {
    'orange' => LekoColors.labelOrange,
    'red' => LekoColors.labelRed,
    _ => LekoColors.labelGreen,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Date Row
// ═══════════════════════════════════════════════════════════════════════════════

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _Tok.iconContainerBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: LekoColors.secondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _Tok.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat.yMMMd().format(date),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _Tok.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _Tok.textPlaceholder,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Note Row
// ═══════════════════════════════════════════════════════════════════════════════

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _Tok.iconContainerBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.edit_note_outlined,
              size: 18,
              color: LekoColors.secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Note',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _Tok.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _Tok.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What was this for?',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: _Tok.textPlaceholder,
                    ),
                    filled: true,
                    fillColor: _Tok.bgTop.withValues(alpha: 0.6),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _Tok.borderSubtle,
                        width: 0.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _Tok.borderSubtle,
                        width: 0.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: _Tok.borderAmount,
                        width: 1,
                      ),
                    ),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Label Chips Section
// ═══════════════════════════════════════════════════════════════════════════════

class _LabelSection extends StatelessWidget {
  const _LabelSection({
    required this.effectiveLabel,
    required this.isOverridden,
    required this.onChanged,
    required this.onReset,
  });

  final SpendLabel effectiveLabel;
  final bool isOverridden;
  final ValueChanged<SpendLabel> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Spending Label',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _Tok.textSecondary,
                letterSpacing: 0.1,
              ),
            ),
            if (isOverridden) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onReset,
                child: const Text(
                  'reset',
                  style: TextStyle(
                    color: LekoColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              SpendLabel.values.map((l) {
                final isActive = effectiveLabel == l;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _LabelChip(
                    label: l,
                    isActive: isActive,
                    onTap: () => onChanged(l),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final SpendLabel label;
  final bool isActive;
  final VoidCallback onTap;

  static const _chipData = <SpendLabel, _ChipStyle>{
    SpendLabel.green: _ChipStyle(
      bg: Color(0xFFE6EBE8), // muted sage
      activeBg: Color(0xFFDBE5DF),
      accent: Color(0xFF6C8C7B),
      icon: Icons.eco_outlined,
      name: 'Needs',
    ),
    SpendLabel.orange: _ChipStyle(
      bg: Color(0xFFF7EBE4), // soft apricot-peach
      activeBg: Color(0xFFF0DED3),
      accent: Color(0xFFD48D6A),
      icon: Icons.star_outline_rounded,
      name: 'Wants',
    ),
    SpendLabel.red: _ChipStyle(
      bg: Color(0xFFF6E7E5), // dusty blush-coral
      activeBg: Color(0xFFEED8D5),
      accent: Color(0xFFC76D68),
      icon: Icons.warning_amber_rounded,
      name: 'Splurge',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = _chipData[label]!;
    final bg = isActive ? style.activeBg : style.bg;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(_Tok.rChip),
          border: Border.all(
            color:
                isActive
                    ? style.accent.withValues(alpha: 0.35)
                    : style.accent.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: style.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 10, color: Colors.white),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(style.icon, size: 16, color: style.accent),
              ),
            Text(
              style.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: style.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipStyle {
  const _ChipStyle({
    required this.bg,
    required this.activeBg,
    required this.accent,
    required this.icon,
    required this.name,
  });
  final Color bg;
  final Color activeBg;
  final Color accent;
  final IconData icon;
  final String name;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Save CTA
// ═══════════════════════════════════════════════════════════════════════════════

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isValid,
    required this.isSaving,
    required this.onPressed,
  });

  final bool isValid;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = isValid && !isSaving;

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: enabled ? _Tok.ctaEnabled : _Tok.ctaDisabled,
          borderRadius: BorderRadius.circular(_Tok.rCta),
          boxShadow:
              enabled
                  ? [
                    BoxShadow(
                      color: _Tok.ctaEnabled.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : null,
        ),
        child: Center(
          child:
              isSaving
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(
                    'Save Expense',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          enabled ? _Tok.ctaTextEnabled : _Tok.ctaTextDisabled,
                      letterSpacing: 0.2,
                    ),
                  ),
        ),
      ),
    );
  }
}
