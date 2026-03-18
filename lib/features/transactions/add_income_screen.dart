import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/ledger_providers.dart';
import '../../core/providers/recurring_income_providers.dart';
import '../../core/providers/widget_snapshot_providers.dart';
import '../../core/theme/leko_colors.dart';
import '../../domain/models/enums.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Design tokens (Matching Add Expense)
// ═══════════════════════════════════════════════════════════════════════════════

class _Tok {
  _Tok._();
  static const double rCard = 24;
  static const double rChip = 18;
  static const double rCta = 22;

  static const bgTop = Color(0xFFF7F6F3);
  static const cardBg = Color(0xFFFCFCFA);

  static const textTitle = Color(0xFF24343A);
  static const textPrimary = Color(0xFF263238);
  static const textSecondary = Color(0xFF8C9AA1);
  static const textPlaceholder = Color(0xFFB5BEC1);

  static const borderAmount = Color(0xFFDDE6E3);
  static const borderSubtle = Color(0xFFE9EEEB);
  static const divider = Color(0xFFE9EEEB);

  static const iconContainerBg = Color(0xFFF0F4F3);

  static const ctaEnabled = Color(0xFF163C46);
  static const ctaDisabled = Color(0xFFDCE4E1);
  static const ctaTextEnabled = Color(0xFFFFFFFF);
  static const ctaTextDisabled = Color(0xFFA8B2AF);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Screen
// ═══════════════════════════════════════════════════════════════════════════════

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _amountCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  bool _isRecurring = false;
  IncomeFrequency _recurringFrequency = IncomeFrequency.monthly;

  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _sourceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _amountCtrl.text.isNotEmpty &&
      (double.tryParse(_amountCtrl.text) ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
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
          'Add Income',
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

                  const SizedBox(height: 16),

                  // ── Section 2: Details Card ──
                  _SectionCard(
                    children: [
                      _TextRow(
                        icon: Icons.business_center_outlined,
                        label: 'Source',
                        hint: 'e.g. Day Job, Freelance',
                        controller: _sourceCtrl,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const _CardDivider(),
                      _DateRow(date: _date, onTap: _pickDate),
                      const _CardDivider(),
                      _ToggleRow(
                        label: 'Recurring Income?',
                        icon: Icons.autorenew_rounded,
                        value: _isRecurring,
                        onChanged: (val) => setState(() => _isRecurring = val),
                      ),
                      if (_isRecurring) ...[
                        const _CardDivider(),
                        _FrequencyRow(
                          selected: _recurringFrequency,
                          onChanged:
                              (val) =>
                                  setState(() => _recurringFrequency = val),
                        ),
                      ],
                      const _CardDivider(),
                      _TextRow(
                        icon: Icons.edit_note_outlined,
                        label: 'Note',
                        hint: 'What was this for?',
                        controller: _noteCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        isFilledBg: true,
                      ),
                    ],
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
                    const SizedBox(height: 16),
                    // ── CTA ──
                    _SaveButton(
                      isValid: _isValid,
                      isSaving: _saving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 32), // Generous bottom spacing
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
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      String? recurringId;
      final amount = double.parse(_amountCtrl.text);
      final sourceName =
          _sourceCtrl.text.trim().isEmpty ? 'Income' : _sourceCtrl.text.trim();

      // If marked recurring, create the schedule first
      if (_isRecurring) {
        recurringId = await ref
            .read(recurringIncomeServiceProvider)
            .create(
              name: sourceName,
              frequency: _recurringFrequency,
              nextPaydayDate: _date,
              expectedAmount: amount,
              paydayBehavior: PaydayBehavior.confirmActualOnPayday,
            );
      }

      // Record the immediate ledger entry
      await ref
          .read(ledgerServiceProvider)
          .addIncome(
            amount: amount,
            date: _date,
            postingType: IncomePostingType.manualOneTime,
            source: _sourceCtrl.text.isEmpty ? null : _sourceCtrl.text,
            note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
            linkedRecurringIncomeId: recurringId,
          );

      ref.read(snapshotWriterProvider).writeSnapshot();
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
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
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      decoration: BoxDecoration(
        color: _Tok.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _Tok.borderAmount, width: 1),
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
//  Detail Rows
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

class _TextRow extends StatelessWidget {
  const _TextRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    required this.textCapitalization,
    this.isFilledBg = false,
  });

  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextCapitalization textCapitalization;
  final bool isFilledBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isFilledBg ? 12 : 8,
      ),
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
            child: Icon(icon, size: 18, color: LekoColors.secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFilledBg) ...[
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _Tok.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                TextField(
                  controller: controller,
                  textCapitalization: textCapitalization,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _Tok.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: isFilledBg ? null : label,
                    labelStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _Tok.textSecondary,
                    ),
                    floatingLabelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: LekoColors.secondary,
                    ),
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: _Tok.textPlaceholder,
                    ),
                    filled: isFilledBg,
                    fillColor:
                        isFilledBg ? _Tok.bgTop.withValues(alpha: 0.6) : null,
                    contentPadding:
                        isFilledBg
                            ? const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            )
                            : const EdgeInsets.only(bottom: 8),
                    border:
                        isFilledBg
                            ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _Tok.borderSubtle,
                                width: 0.5,
                              ),
                            )
                            : InputBorder.none,
                    enabledBorder:
                        isFilledBg
                            ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _Tok.borderSubtle,
                                width: 0.5,
                              ),
                            )
                            : InputBorder.none,
                    focusedBorder:
                        isFilledBg
                            ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _Tok.borderAmount,
                                width: 1,
                              ),
                            )
                            : InputBorder.none,
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

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _Tok.iconContainerBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: LekoColors.secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _Tok.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: LekoColors.secondary,
            activeTrackColor: LekoColors.secondary.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

class _FrequencyRow extends StatelessWidget {
  const _FrequencyRow({required this.selected, required this.onChanged});

  final IncomeFrequency selected;
  final ValueChanged<IncomeFrequency> onChanged;

  String _formatFreq(IncomeFrequency f) {
    return switch (f) {
      IncomeFrequency.weekly => 'Weekly',
      IncomeFrequency.biweekly => 'Bi-weekly',
      IncomeFrequency.monthly => 'Monthly',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequency',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _Tok.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                IncomeFrequency.values.map((f) {
                  final isEq = selected == f;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () => onChanged(f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.fastOutSlowIn,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isEq
                                  ? LekoColors.secondary.withValues(
                                    alpha: 0.12,
                                  )
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(_Tok.rChip),
                          border: Border.all(
                            color:
                                isEq
                                    ? LekoColors.secondary.withValues(
                                      alpha: 0.5,
                                    )
                                    : _Tok.borderSubtle,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _formatFreq(f),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isEq ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isEq
                                    ? LekoColors.secondary
                                    : _Tok.textPlaceholder,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CTA Widget
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
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid ? _Tok.ctaEnabled : _Tok.ctaDisabled,
          foregroundColor: isValid ? _Tok.ctaTextEnabled : _Tok.ctaTextDisabled,
          elevation: isValid ? 4 : 0,
          shadowColor: _Tok.ctaEnabled.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_Tok.rCta),
          ),
        ),
        onPressed: isValid && !isSaving ? onPressed : null,
        child:
            isSaving
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                : const Text(
                  'Save Income',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
      ),
    );
  }
}
