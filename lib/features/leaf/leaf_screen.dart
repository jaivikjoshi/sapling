import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/leaf_providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/models/enums.dart';
import 'leaf_assistant_responses.dart';
import 'leaf_context.dart';
import 'leaf_models.dart';

class LeafScreen extends ConsumerStatefulWidget {
  const LeafScreen({super.key});

  @override
  ConsumerState<LeafScreen> createState() => _LeafScreenState();
}

class _LeafScreenState extends ConsumerState<LeafScreen> {
  final _scroll = ScrollController();
  late final TextEditingController _composer;

  @override
  void initState() {
    super.initState();
    _composer = TextEditingController();
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Limit bottom padding to keep it smoothly above the glassy nav bar
    final navPad = bottomInset > 72.0 ? bottomInset : 106.0;
    final ctx = ref.watch(leafContextProvider);
    final heroBrief = ref.watch(leafHeroBriefingProvider);
    final convo = ref.watch(leafConversationProvider);

    ref.listen<LeafConversationState>(leafConversationProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.isLoading != next.isLoading) {
        _scrollToEnd();
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _LeafPalette.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _LeafHeader(
                            name: ctx.greetingName,
                            mode: ctx.allowanceMode,
                            balance: ctx.balance,
                          ),
                          const SizedBox(height: 22),
                          _HeroBriefingCard(text: heroBrief),
                          const SizedBox(height: 18),
                          _InsightGrid(contextData: ctx),
                          const SizedBox(height: 20),
                          _QuickAskChips(
                            prompts: convo.suggestedPrompts,
                            onChip: (prompt) {
                              ref
                                  .read(leafConversationProvider.notifier)
                                  .submitFreeText(prompt);
                              _scrollToEnd();
                            },
                          ),
                          const SizedBox(height: 20),
                          const _SectionLabel('Conversation'),
                          const SizedBox(height: 10),
                        ]),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final m = convo.messages[i];
                            return _ChatBubble(
                              message: m,
                              isPendingAction: identical(
                                convo.pendingAction,
                                m.action,
                              ),
                            );
                          },
                          childCount: convo.messages.length,
                        ),
                      ),
                    ),
                    if (convo.isLoading)
                      const SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: _LoadingBubble(),
                        ),
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: navPad + 88)),
                  ],
                ),
              ),
              if (convo.pendingAction != null)
                _PendingActionBar(
                  action: convo.pendingAction!,
                  onConfirm: () {
                    ref
                        .read(leafConversationProvider.notifier)
                        .confirmPendingAction();
                    _scrollToEnd();
                  },
                  onCancel: () {
                    ref
                        .read(leafConversationProvider.notifier)
                        .cancelPendingAction();
                    _scrollToEnd();
                  },
                ),
              _ComposerBar(
                controller: _composer,
                bottomPadding: navPad,
                isLoading: convo.isLoading,
                onSend: () {
                  final t = _composer.text;
                  if (t.trim().isEmpty || convo.isLoading) return;
                  _composer.clear();
                  ref.read(leafConversationProvider.notifier).submitFreeText(t);
                  _scrollToEnd();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _LeafPalette {
  static const background = Color(0xFFFBF9F6); // Warm Cream matches the rest of app
  static const surface = Colors.white;
  static const surfaceLift = Color(0xFFF8FAFC);
  static const outline = Color(0xFFE9EDF4);
  static const navy = Color(0xFF0F172A); // App's primary dark color
  static const mint = Color(0xFF3B9797); // Leko's deep seafoam
  static const mintDim = Color(0xFF45A5A5);
  static const ember = Color(0xFFC75D53); // Muted red for errors/bills
  static const textPrimary = Color(0xFF0E1830);
  static const textSecondary = Color(0xFF7D8C94);
  static const textMuted = Color(0xFF8B96A8);
}

class _LeafHeader extends StatelessWidget {
  const _LeafHeader({
    required this.name,
    required this.mode,
    this.balance,
  });

  final String name;
  final AllowanceMode mode;
  final double? balance;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Leaf AI',
                style: TextStyle(
                  color: _LeafPalette.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your dynamic financial assistant.',
                style: const TextStyle(
                  color: _LeafPalette.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (balance != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Balance ${formatCurrency(balance!)}',
                  style: const TextStyle(
                    color: _LeafPalette.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x100F1932),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.spa_rounded,
            color: _LeafPalette.mint,
            size: 22,
          ),
        ),
      ],
    );
  }
}

class _HeroBriefingCard extends StatelessWidget {
  const _HeroBriefingCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
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
              const Icon(
                Icons.auto_awesome_rounded,
                color: _LeafPalette.mint,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'TODAY’S BRIEFING',
                style: TextStyle(
                  color: _LeafPalette.mint,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: const TextStyle(
              color: _LeafPalette.textPrimary,
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightGrid extends StatelessWidget {
  const _InsightGrid({required this.contextData});

  final LeafContext contextData;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.22,
      children: [
        _InsightTile(
          icon: Icons.wb_sunny_rounded,
          title: 'Allowance',
          subtitle: leafInsightAllowanceSubtitle(contextData),
          accent: _LeafPalette.mint,
        ),
        _InsightTile(
          icon: Icons.receipt_long_rounded,
          title: 'Bills ahead',
          subtitle: leafInsightBillsSubtitle(contextData),
          accent: const Color(0xFFD98A5B),
        ),
        _InsightTile(
          icon: Icons.flag_rounded,
          title: 'Goal focus',
          subtitle: leafInsightGoalSubtitle(contextData),
          accent: const Color(0xFF5C8CB3),
        ),
        _InsightTile(
          icon: Icons.show_chart_rounded,
          title: 'Latest move',
          subtitle: leafInsightActivitySubtitle(contextData),
          accent: _LeafPalette.navy,
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const Spacer(),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _LeafPalette.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _LeafPalette.textPrimary,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _LeafPalette.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: _LeafPalette.outline,
          ),
        ),
      ],
    );
  }
}

class _QuickAskChips extends StatelessWidget {
  const _QuickAskChips({
    required this.prompts,
    required this.onChip,
  });

  final List<String> prompts;
  final void Function(String) onChip;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        spacing: 8,
        children: prompts
            .map((prompt) => _AskChip(label: prompt, onTap: () => onChip(prompt)))
            .toList(),
      ),
    );
  }
}

class _AskChip extends StatelessWidget {
  const _AskChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
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
            label,
            style: const TextStyle(
              color: _LeafPalette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isPendingAction,
  });

  final LeafChatMessage message;
  final bool isPendingAction;

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    if (!user && message.action != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _ActionPreviewCard(
            text: message.text,
            action: message.action!,
            isPending: isPendingAction,
            success: message.success,
            isError: message.kind == LeafMessageKind.error,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: user ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.86,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: user ? _LeafPalette.navy : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(user ? 20 : 6),
                bottomRight: Radius.circular(user ? 6 : 20),
              ),
              boxShadow: user
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x0C0F172A),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                message.text,
                style: TextStyle(
                  color: user ? Colors.white : _LeafPalette.textPrimary,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.bottomPadding,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final double bottomPadding;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _LeafPalette.background.withValues(alpha: 0.0),
              _LeafPalette.background.withValues(alpha: 0.94),
              _LeafPalette.background,
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x100F172A),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(
                    color: _LeafPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: _LeafPalette.mint,
                  decoration: const InputDecoration(
                    hintText: 'Ask Leaf about your budget…',
                    hintStyle: TextStyle(
                      color: _LeafPalette.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: _LeafPalette.navy,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: isLoading ? null : onSend,
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingActionBar extends StatelessWidget {
  const _PendingActionBar({
    required this.action,
    required this.onConfirm,
    required this.onCancel,
  });

  final LeafPendingAction action;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.intent.label,
                  style: const TextStyle(
                    color: _LeafPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Review and confirm before Leaf changes anything.',
                  style: TextStyle(
                    color: _LeafPalette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: _LeafPalette.textSecondary),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: _LeafPalette.mint,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C0F172A),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_LeafPalette.mint),
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Leaf is thinking…',
                style: TextStyle(
                  color: _LeafPalette.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPreviewCard extends StatelessWidget {
  const _ActionPreviewCard({
    required this.text,
    required this.action,
    required this.isPending,
    required this.success,
    required this.isError,
  });

  final String text;
  final LeafPendingAction action;
  final bool isPending;
  final bool? success;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent = isError
        ? _LeafPalette.ember
        : success == true
            ? _LeafPalette.mint
            : const Color(0xFF5C8CB3);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.9,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C0F172A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isError
                        ? 'Needs attention'
                        : success == true
                            ? 'Completed'
                            : isPending
                                ? 'Awaiting confirmation'
                                : 'Preview',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  action.intent.label,
                  style: const TextStyle(
                    color: _LeafPalette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                color: _LeafPalette.textPrimary,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._actionRows(action).map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PreviewRow(label: row.$1, value: row.$2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              color: _LeafPalette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _LeafPalette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

List<(String, String)> _actionRows(LeafPendingAction action) {
  final rows = <(String, String)>[];
  final data = action.data;

  void addRow(String label, Object? value) {
    if (value == null) return;
    final rendered = value.toString().trim();
    if (rendered.isEmpty || rendered == 'null') return;
    rows.add((label, rendered));
  }

  addRow('Amount', _formatPreviewAmount(data['amount']));
  addRow('Category', data['category_name']);
  addRow('Merchant', data['merchant']);
  addRow('Source', data['source']);
  addRow('Bill', data['bill_name']);
  addRow('Goal', data['name']);
  addRow('Date', _formatPreviewDate(data['date']));
  addRow('Target', _formatPreviewAmount(data['target_amount']));

  if (action.missingFields.isNotEmpty) {
    rows.add(('Missing', action.missingFields.join(', ')));
  }

  return rows;
}

String? _formatPreviewAmount(Object? raw) {
  final amount = switch (raw) {
    final num value => value.toDouble(),
    final String value => double.tryParse(value),
    _ => null,
  };
  if (amount == null) return null;
  return formatCurrency(amount);
}

String? _formatPreviewDate(Object? raw) {
  if (raw is! String || raw.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[parsed.month]} ${parsed.day}, ${parsed.year}';
}
