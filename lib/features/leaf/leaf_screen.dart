import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/leaf_providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/models/enums.dart';
import 'leaf_assistant_responses.dart';
import 'leaf_context.dart';

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
    final navPad = bottomInset + 72;
    final ctx = ref.watch(leafContextProvider);
    final heroBrief = ref.watch(leafHeroBriefingProvider);
    final convo = ref.watch(leafConversationProvider);

    ref.listen<LeafConversationState>(leafConversationProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToEnd();
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _LeafPalette.bgDeep,
        body: Stack(
          children: [
            const _LeafAtmosphere(),
            SafeArea(
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
                                onChip: (k) {
                                  ref.read(leafConversationProvider.notifier).askKind(k);
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
                                return _ChatBubble(message: m);
                              },
                              childCount: convo.messages.length,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: SizedBox(height: navPad + 88)),
                      ],
                    ),
                  ),
                  _ComposerBar(
                    controller: _composer,
                    bottomPadding: navPad,
                    onSend: () {
                      final t = _composer.text;
                      _composer.clear();
                      ref.read(leafConversationProvider.notifier).submitFreeText(t);
                      _scrollToEnd();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class _LeafPalette {
  static const bgDeep = Color(0xFF060A0D);
  static const surface = Color(0xFF0E171A);
  static const surfaceLift = Color(0xFF152226);
  static const outline = Color(0x3348B8A8);
  static const mist = Color(0xFF8CB3AD);
  static const leaf = Color(0xFF6FD4B8);
  static const leafDim = Color(0xFF3D8F7E);
  static const ember = Color(0xFFE3A587);
  static const text = Color(0xFFF3EEE6);
  static const textSoft = Color(0xFFB9C8C4);
  static const textMuted = Color(0xFF7A8F8B);
}

class _LeafAtmosphere extends StatelessWidget {
  const _LeafAtmosphere();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF05080C),
                Color(0xFF0A1214),
                Color(0xFF0D1819),
              ],
            ),
          ),
          child: SizedBox.expand(),
        ),
        Positioned(
          top: -60,
          right: -30,
          child: _glowOrb(200, _LeafPalette.leaf.withValues(alpha: 0.07)),
        ),
        Positioned(
          top: 120,
          left: -50,
          child: _glowOrb(160, const Color(0xFF5B8FA8).withValues(alpha: 0.06)),
        ),
        Positioned(
          bottom: 200,
          right: 20,
          child: _glowOrb(120, _LeafPalette.ember.withValues(alpha: 0.05)),
        ),
      ],
    );
  }

}

Widget _glowOrb(double size, Color c) {
  return IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [c, Colors.transparent]),
      ),
    ),
  );
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
    final display = name.isEmpty ? 'there' : name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _LeafPalette.leaf.withValues(alpha: 0.35),
                    _LeafPalette.leafDim.withValues(alpha: 0.2),
                  ],
                ),
                border: Border.all(color: _LeafPalette.outline),
              ),
              child: const Icon(
                Icons.spa_rounded,
                color: _LeafPalette.leaf,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leaf',
                    style: TextStyle(
                      color: _LeafPalette.text,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Budget copilot · ${mode == AllowanceMode.paycheck ? 'Paycheck rhythm' : 'Goal pace'}',
                    style: const TextStyle(
                      color: _LeafPalette.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Good to see you, $display.',
          style: const TextStyle(
            color: _LeafPalette.textSoft,
            fontSize: 16,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (balance != null) ...[
          const SizedBox(height: 6),
          Text(
            'Posted balance ${formatCurrency(balance!)}',
            style: TextStyle(
              color: _LeafPalette.mist.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _LeafPalette.surfaceLift.withValues(alpha: 0.95),
            _LeafPalette.surface.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: _LeafPalette.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
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
                  color: _LeafPalette.leaf.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _LeafPalette.leaf.withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  'Today’s briefing',
                  style: TextStyle(
                    color: _LeafPalette.leaf,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: const TextStyle(
              color: _LeafPalette.text,
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
          icon: Icons.wb_sunny_outlined,
          title: 'Allowance',
          subtitle: leafInsightAllowanceSubtitle(contextData),
          accent: _LeafPalette.leaf,
        ),
        _InsightTile(
          icon: Icons.receipt_long_outlined,
          title: 'Bills ahead',
          subtitle: leafInsightBillsSubtitle(contextData),
          accent: _LeafPalette.ember,
        ),
        _InsightTile(
          icon: Icons.flag_outlined,
          title: 'Goal focus',
          subtitle: leafInsightGoalSubtitle(contextData),
          accent: const Color(0xFF8FA8E8),
        ),
        _InsightTile(
          icon: Icons.show_chart_rounded,
          title: 'Latest move',
          subtitle: leafInsightActivitySubtitle(contextData),
          accent: _LeafPalette.mist,
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
        color: _LeafPalette.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _LeafPalette.outline),
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
              color: _LeafPalette.textSoft,
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
  const _QuickAskChips({required this.onChip});

  final void Function(LeafQueryKind) onChip;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _AskChip(
          label: 'Spending today',
          onTap: () => onChip(LeafQueryKind.spendingToday),
        ),
        _AskChip(
          label: 'Bills',
          onTap: () => onChip(LeafQueryKind.bills),
        ),
        _AskChip(
          label: 'Goal',
          onTap: () => onChip(LeafQueryKind.goal),
        ),
        _AskChip(
          label: 'This cycle',
          onTap: () => onChip(LeafQueryKind.thisCycle),
        ),
      ],
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
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _LeafPalette.surfaceLift.withValues(alpha: 0.65),
            border: Border.all(color: _LeafPalette.outline),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: _LeafPalette.textSoft,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final LeafChatMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
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
              color: user
                  ? _LeafPalette.leafDim.withValues(alpha: 0.45)
                  : _LeafPalette.surfaceLift.withValues(alpha: 0.88),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(user ? 20 : 6),
                bottomRight: Radius.circular(user ? 6 : 20),
              ),
              border: Border.all(
                color: user
                    ? _LeafPalette.leaf.withValues(alpha: 0.25)
                    : _LeafPalette.outline,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                message.text,
                style: TextStyle(
                  color: user ? _LeafPalette.text : _LeafPalette.textSoft,
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
    required this.onSend,
  });

  final TextEditingController controller;
  final double bottomPadding;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _LeafPalette.bgDeep.withValues(alpha: 0),
              _LeafPalette.bgDeep.withValues(alpha: 0.94),
              _LeafPalette.bgDeep,
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _LeafPalette.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: _LeafPalette.outline),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(
                    color: _LeafPalette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: _LeafPalette.leaf,
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
              color: _LeafPalette.leaf.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: onSend,
                borderRadius: BorderRadius.circular(22),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: Color(0xFF06221C),
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
