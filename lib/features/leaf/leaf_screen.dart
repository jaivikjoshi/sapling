import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers/integration_providers.dart';
import '../../core/providers/leaf_providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/leko_mark.dart';
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

  /// Opens a bottom sheet for attaching receipts/statements. Handles
  /// compression lightly (image_picker's imageQuality) so payloads stay
  /// reasonable when they get forwarded to Gemini as base64 inline_data.
  Future<void> _pickAttachments({required int currentCount}) async {
    if (currentCount >= 3) {
      _showAttachmentLimitToast();
      return;
    }

    final source = await showModalBottomSheet<_AttachmentSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AttachmentSourceSheet(),
    );
    if (source == null || !mounted) return;

    try {
      final attachment = await _loadAttachmentFromSource(source);
      if (attachment == null || !mounted) return;
      if (attachment.sizeBytes != null &&
          attachment.sizeBytes! > 6 * 1024 * 1024) {
        _showSnack('File is too large. Pick something under 6 MB.');
        return;
      }
      ref
          .read(leafConversationProvider.notifier)
          .addStagedAttachment(attachment);
    } catch (_) {
      if (mounted) _showSnack('Could not read that file.');
    }
  }

  Future<LeafAttachment?> _loadAttachmentFromSource(
    _AttachmentSource source,
  ) async {
    switch (source) {
      case _AttachmentSource.camera:
      case _AttachmentSource.photo:
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source:
              source == _AttachmentSource.camera
                  ? ImageSource.camera
                  : ImageSource.gallery,
          imageQuality: 82,
          maxWidth: 2048,
        );
        if (picked == null) return null;
        final bytes = await picked.readAsBytes();
        return LeafAttachment(
          name: picked.name,
          mime: _mimeForImageName(picked.name),
          dataBase64: base64Encode(bytes),
          sizeBytes: bytes.length,
        );
      case _AttachmentSource.pdf:
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: true,
        );
        final file = result?.files.first;
        if (file == null) return null;
        final bytes =
            file.bytes ??
            (file.path != null ? await File(file.path!).readAsBytes() : null);
        if (bytes == null) return null;
        return LeafAttachment(
          name: file.name,
          mime: 'application/pdf',
          dataBase64: base64Encode(bytes),
          sizeBytes: bytes.length,
        );
    }
  }

  void _showAttachmentLimitToast() {
    _showSnack('You can attach up to 3 files per message.');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _startVoiceInput() async {
    final result = await ref.read(voiceInputProvider).listen();
    if (!mounted) return;
    if (result.permissionDenied) {
      _showSnack('Voice input needs microphone permission on this platform.');
      return;
    }
    final transcript = result.transcript.trim();
    if (transcript.isEmpty) {
      _showSnack('I did not catch anything. Try typing it for now.');
      return;
    }
    _composer.clear();
    await ref
        .read(leafConversationProvider.notifier)
        .submitFreeText(transcript);
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Keep the composer resting just above the glass nav bar
    final navPad = bottomInset > 72.0 ? bottomInset : 106.0;
    final ctx = ref.watch(leafContextProvider);
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
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _LeafHeader(
                            name: ctx.greetingName,
                            onNewChat: () {
                              ref
                                  .read(leafConversationProvider.notifier)
                                  .clearConversation();
                            },
                          ),
                          const SizedBox(height: 22),
                          _SafeToSpendCard(contextData: ctx),
                          const SizedBox(height: 16),
                          _SuggestedPrompts(
                            prompts: convo.suggestedPrompts,
                            onTap: (prompt) {
                              ref
                                  .read(leafConversationProvider.notifier)
                                  .submitFreeText(prompt);
                              _scrollToEnd();
                            },
                          ),
                          const SizedBox(height: 18),
                        ]),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final m = convo.messages[i];
                          return _ChatBubble(
                            message: m,
                            isPendingAction: identical(
                              convo.pendingAction,
                              m.action,
                            ),
                            onSelectOption: (option) {
                              ref
                                  .read(leafConversationProvider.notifier)
                                  .selectClarificationOption(
                                    source: m,
                                    option: option,
                                  );
                              _scrollToEnd();
                            },
                          );
                        }, childCount: convo.messages.length),
                      ),
                    ),
                    if (convo.isLoading)
                      const SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverToBoxAdapter(child: _LoadingBubble()),
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: navPad + 88)),
                  ],
                ),
              ),
              if (convo.pendingAction != null)
                _PendingActionBar(
                  action: convo.pendingAction!,
                  confirmEnabled: !convo.isLoading,
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
                attachments: convo.stagedAttachments,
                onRemoveAttachment: (index) {
                  ref
                      .read(leafConversationProvider.notifier)
                      .removeStagedAttachmentAt(index);
                },
                onAttach:
                    () => _pickAttachments(
                      currentCount: convo.stagedAttachments.length,
                    ),
                onVoice: _startVoiceInput,
                onSend: () {
                  final t = _composer.text;
                  final hasText = t.trim().isNotEmpty;
                  final hasAttachments = convo.stagedAttachments.isNotEmpty;
                  if ((!hasText && !hasAttachments) || convo.isLoading) return;
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

/// Palette aligned with the Home / Goals / Reports / Settings surfaces so the
/// Leaf tab feels like the same product instead of a branded landing page.
abstract final class _LeafPalette {
  static const background = Color(0xFFF5F7FB); // Cool light gray (matches Home)
  static const surface = Colors.white;
  static const outline = Color(0xFFE7ECF4);
  static const navy = Color(0xFF0F172A); // Bold title / user bubble
  static const navyDeep = Color(0xFF132440); // Hero card (same as Home)
  static const mint = Color(0xFF3B9797); // Leko jade
  static const mintSoft = Color(0xFFF0FDFA);
  static const ember = Color(0xFFC75D53); // Error / overspend only
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF8B96A8);
  static const summaryMuted = Color(0x8CFFFFFF);
  static const chipSurface = Colors.white;
  static const chipBorder = Color(0xFFE7ECF4);
}

class _LeafHeader extends StatelessWidget {
  const _LeafHeader({required this.name, required this.onNewChat});

  final String name;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final greetingName = trimmed.isEmpty ? 'there' : trimmed;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greetingPrefix()}, $greetingName',
                style: const TextStyle(
                  color: _LeafPalette.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _LeafPalette.navyDeep,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: LekoMark(size: 22, color: Color(0xFFB4B6B7)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Leaf',
                    style: TextStyle(
                      color: _LeafPalette.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(
          icon: Icons.edit_note_rounded,
          tooltip: 'New chat',
          onTap: onNewChat,
        ),
      ],
    );
  }
}

String _greetingPrefix() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
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
          child: Icon(icon, color: _LeafPalette.textPrimary, size: 22),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Hero card answers the one question the AI page exists for: what's safe to
/// spend right now. Styled to match Home's weekly summary card so the page
/// feels native to the rest of the app.
class _SafeToSpendCard extends StatelessWidget {
  const _SafeToSpendCard({required this.contextData});

  final LeafContext contextData;

  @override
  Widget build(BuildContext context) {
    final remaining = contextData.remainingToday;
    final daily = contextData.dailyAllowance;
    final over = remaining != null && remaining < 0;
    final primaryValue =
        remaining != null ? formatCurrency(remaining.abs()) : '—';

    final subtitle = _safeToSpendSubtitle(contextData);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: _LeafPalette.navyDeep,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x42132440),
            blurRadius: 30,
            offset: Offset(0, 16),
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
                  over ? 'OVER TODAY' : 'SAFE TO SPEND TODAY',
                  style: const TextStyle(
                    color: _LeafPalette.summaryMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: LekoMark(size: 22, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (over)
                const Padding(
                  padding: EdgeInsets.only(right: 4, bottom: 6),
                  child: Text(
                    '−',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Flexible(
                child: Text(
                  primaryValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (daily != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'of ${formatCurrency(daily)}',
                    style: const TextStyle(
                      color: _LeafPalette.summaryMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                over ? Icons.trending_up_rounded : Icons.trending_flat_rounded,
                size: 18,
                color: over ? _LeafPalette.ember : _LeafPalette.mint,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: over ? _LeafPalette.ember : const Color(0xFF7FE4C7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _safeToSpendSubtitle(LeafContext ctx) {
  final left = ctx.remainingToday;
  final daily = ctx.dailyAllowance;
  if (left == null || daily == null) return 'Syncing today\'s allowance';
  if (left >= 0) {
    final pct = daily > 0 ? (left / daily * 100).round() : 0;
    return '$pct% left today';
  }
  return 'Over pace today';
}

class _SuggestedPrompts extends StatelessWidget {
  const _SuggestedPrompts({required this.prompts, required this.onTap});

  final List<String> prompts;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final prompt = prompts[i];
          return _AskChip(label: prompt, onTap: () => onTap(prompt));
        },
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _LeafPalette.chipSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _LeafPalette.chipBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 14,
                color: _LeafPalette.mint,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: _LeafPalette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
    required this.onSelectOption,
  });

  final LeafChatMessage message;
  final bool isPendingAction;
  final void Function(LeafClarificationOption option) onSelectOption;

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    final hasOptions = message.clarificationOptions.isNotEmpty;

    // Assistant messages that come with a pending/confirmed action render the
    // preview card; attach clarification options below it when present.
    if (!user && message.action != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActionPreviewCard(
                text: message.text,
                action: message.action!,
                isPending: isPendingAction,
                success: message.success,
                isError: message.kind == LeafMessageKind.error,
              ),
              if (hasOptions) ...[
                const SizedBox(height: 10),
                _ClarificationOptions(
                  options: message.clarificationOptions,
                  onTap: onSelectOption,
                ),
              ],
            ],
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
            maxWidth: MediaQuery.sizeOf(context).width * 0.84,
          ),
          child: Column(
            crossAxisAlignment:
                user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (user && message.attachments.isNotEmpty) ...[
                _InlineAttachmentRow(attachments: message.attachments),
                if (message.text.trim().isNotEmpty) const SizedBox(height: 8),
              ],
              if (message.text.trim().isNotEmpty)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: user ? _LeafPalette.navy : _LeafPalette.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(user ? 20 : 6),
                      bottomRight: Radius.circular(user ? 6 : 20),
                    ),
                    border:
                        user ? null : Border.all(color: _LeafPalette.outline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: user ? Colors.white : _LeafPalette.textPrimary,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              if (!user && hasOptions) ...[
                const SizedBox(height: 10),
                _ClarificationOptions(
                  options: message.clarificationOptions,
                  onTap: onSelectOption,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders tappable clarification options. Tapping one calls back with the
/// option so the conversation controller can merge the `patch` into the
/// pending action and move forward without a server round-trip.
class _ClarificationOptions extends StatelessWidget {
  const _ClarificationOptions({required this.options, required this.onTap});

  final List<LeafClarificationOption> options;
  final void Function(LeafClarificationOption) onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          _OptionCard(option: option, onTap: () => onTap(option)),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.option, required this.onTap});

  final LeafClarificationOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _LeafPalette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _LeafPalette.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: _LeafPalette.mint,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      color: _LeafPalette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (option.subtitle != null && option.subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        option.subtitle!,
                        style: const TextStyle(
                          color: _LeafPalette.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
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

class _InlineAttachmentRow extends StatelessWidget {
  const _InlineAttachmentRow({required this.attachments});

  final List<LeafAttachmentPreview> attachments;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final attachment in attachments)
          _AttachmentPill(
            icon:
                attachment.isImage
                    ? Icons.image_outlined
                    : Icons.picture_as_pdf_rounded,
            label: attachment.name,
            tone: _AttachmentPillTone.onNavy,
          ),
      ],
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.bottomPadding,
    required this.isLoading,
    required this.onSend,
    required this.attachments,
    required this.onAttach,
    required this.onVoice,
    required this.onRemoveAttachment,
  });

  final TextEditingController controller;
  final double bottomPadding;
  final bool isLoading;
  final VoidCallback onSend;
  final List<LeafAttachment> attachments;
  final VoidCallback onAttach;
  final VoidCallback onVoice;
  final void Function(int index) onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding),
        decoration: const BoxDecoration(color: _LeafPalette.background),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachments.isNotEmpty) ...[
              _StagedAttachmentRow(
                attachments: attachments,
                onRemove: onRemoveAttachment,
              ),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _LeafPalette.outline),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _AttachButton(
                      enabled: attachments.length < 3 && !isLoading,
                      onTap: onAttach,
                    ),
                    const SizedBox(width: 4),
                    _VoiceButton(enabled: !isLoading, onTap: onVoice),
                    const SizedBox(width: 4),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(
                          color: _LeafPalette.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: _LeafPalette.navy,
                        decoration: const InputDecoration(
                          hintText: 'Ask Leko anything…',
                          hintStyle: TextStyle(
                            color: _LeafPalette.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SendButton(isLoading: isLoading, onTap: onSend),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: enabled ? _LeafPalette.mintSoft : const Color(0xFFF1F4FA),
              shape: BoxShape.circle,
              border: Border.all(color: _LeafPalette.outline),
            ),
            child: Icon(
              Icons.attach_file_rounded,
              size: 18,
              color: enabled ? _LeafPalette.mint : _LeafPalette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  const _VoiceButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Tooltip(
        message: 'Voice input',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: enabled ? Colors.white : const Color(0xFFF1F4FA),
                shape: BoxShape.circle,
                border: Border.all(color: _LeafPalette.outline),
              ),
              child: Icon(
                Icons.mic_none_rounded,
                size: 18,
                color:
                    enabled
                        ? _LeafPalette.textSecondary
                        : _LeafPalette.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StagedAttachmentRow extends StatelessWidget {
  const _StagedAttachmentRow({
    required this.attachments,
    required this.onRemove,
  });

  final List<LeafAttachment> attachments;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final attachment = attachments[i];
          return _AttachmentPill(
            icon:
                attachment.isImage
                    ? Icons.image_outlined
                    : Icons.picture_as_pdf_rounded,
            label: attachment.name,
            tone: _AttachmentPillTone.surface,
            onRemove: () => onRemove(i),
          );
        },
      ),
    );
  }
}

enum _AttachmentPillTone { surface, onNavy }

class _AttachmentPill extends StatelessWidget {
  const _AttachmentPill({
    required this.icon,
    required this.label,
    this.tone = _AttachmentPillTone.surface,
    this.onRemove,
  });

  final IconData icon;
  final String label;
  final _AttachmentPillTone tone;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final onNavy = tone == _AttachmentPillTone.onNavy;
    final background =
        onNavy ? Colors.white.withValues(alpha: 0.14) : Colors.white;
    final border =
        onNavy ? Colors.white.withValues(alpha: 0.22) : _LeafPalette.outline;
    final textColor = onNavy ? Colors.white : _LeafPalette.textPrimary;
    final iconColor = onNavy ? Colors.white : _LeafPalette.mint;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: onNavy ? Colors.white : _LeafPalette.textMuted,
                  ),
                ),
              ),
            ] else
              const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

enum _AttachmentSource { camera, photo, pdf }

class _AttachmentSourceSheet extends StatelessWidget {
  const _AttachmentSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _LeafPalette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _LeafPalette.outline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Attach a receipt or statement',
                  style: TextStyle(
                    color: _LeafPalette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            _AttachmentSourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Choose photo',
              onTap: () => Navigator.of(context).pop(_AttachmentSource.photo),
            ),
            _AttachmentSourceTile(
              icon: Icons.photo_camera_outlined,
              label: 'Take a photo',
              onTap: () => Navigator.of(context).pop(_AttachmentSource.camera),
            ),
            _AttachmentSourceTile(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Attach a PDF',
              onTap: () => Navigator.of(context).pop(_AttachmentSource.pdf),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentSourceTile extends StatelessWidget {
  const _AttachmentSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          border:
              isLast
                  ? null
                  : const Border(
                    bottom: BorderSide(color: _LeafPalette.outline, width: 1),
                  ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _LeafPalette.mintSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: _LeafPalette.mint),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: _LeafPalette.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _mimeForImageName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
  return 'image/jpeg';
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: _LeafPalette.navy,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: 40,
            height: 40,
            child:
                isLoading
                    ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
          ),
        ),
      ),
    );
  }
}

class _PendingActionBar extends StatelessWidget {
  const _PendingActionBar({
    required this.action,
    required this.confirmEnabled,
    required this.onConfirm,
    required this.onCancel,
  });

  final LeafPendingAction action;
  final bool confirmEnabled;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _LeafPalette.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F172A),
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
                  'Review and confirm before Leko changes anything.',
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
            style: TextButton.styleFrom(
              foregroundColor: _LeafPalette.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: confirmEnabled ? onConfirm : null,
            style: FilledButton.styleFrom(
              backgroundColor: _LeafPalette.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
            border: Border.all(color: _LeafPalette.outline),
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
                'Leko is thinking…',
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
    final accent =
        isError
            ? _LeafPalette.ember
            : success == true
            ? _LeafPalette.mint
            : _LeafPalette.navy;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.88,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _LeafPalette.outline),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
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
