import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/auth_providers.dart';
import 'auth_shell.dart';

class ConfirmEmailScreen extends ConsumerStatefulWidget {
  const ConfirmEmailScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends ConsumerState<ConfirmEmailScreen> {
  bool _resending = false;
  String? _resendError;
  bool _resendSuccess = false;
  bool _verified = false;
  bool _linkExpired = false;
  Timer? _linkCheckTimer;

  @override
  void initState() {
    super.initState();
    _startLinkChecker();
  }

  @override
  void dispose() {
    _linkCheckTimer?.cancel();
    super.dispose();
  }

  /// Poll for auth link in case uriLinkStream didn't emit (platform quirk).
  void _startLinkChecker() {
    _linkCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted || _verified) return;
      try {
        final uri = await AppLinks().getLatestLink();
        if (uri != null &&
            uri.scheme == 'com.jaivik.leko' &&
            (uri.host == 'auth-callback' || uri.host == 'login-callback')) {
          await Supabase.instance.client.auth.getSessionFromUrl(uri);
        }
      } catch (_) {}
    });
  }

  Future<void> _resend() async {
    final email = widget.email?.trim();
    if (email == null || email.isEmpty) {
      setState(() => _resendError = 'Email address missing. Please go back and sign up again.');
      return;
    }
    setState(() {
      _resending = true;
      _resendError = null;
      _resendSuccess = false;
      _linkExpired = false;
    });
    try {
      await ref.read(supabaseClientProvider).auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'com.jaivik.leko://auth-callback',
      );
      if (!mounted) return;
      setState(() {
        _resending = false;
        _resendError = null;
        _resendSuccess = true;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      final expired = msg.contains('expired') || msg.contains('invalid');
      final rateExceeded = msg.contains('rate') || msg.contains('limit');
      setState(() {
        _resending = false;
        _resendError = expired
            ? null
            : rateExceeded
                ? 'Too many emails sent. Please wait about an hour and try again.'
                : e.message;
        _linkExpired = expired;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      final rateExceeded = msg.contains('rate') || msg.contains('limit');
      setState(() {
        _resending = false;
        _resendError = rateExceeded
            ? 'Too many emails sent. Please wait about an hour and try again.'
            : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      next.whenOrNull(
        data: (event) {
          if (event.session != null) {
            _onVerified();
          }
        },
        error: (_, __) {
          setState(() => _linkExpired = true);
        },
      );
    });
    ref.watch(authStateProvider);

    return AuthScaffold(
      title: 'Confirm your email',
      subtitle: 'We sent a verification link to your inbox.',
      onBack: _verified ? null : () => context.go('/welcome'),
      child: _verified
          ? _buildSuccessState()
          : _buildWaitingState(),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.4),
            ),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'Email verified!',
                style: TextStyle(
                  color: AuthPalette.headline,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Taking you to get set up…',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AuthPalette.subtext,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AuthPalette.gold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.mark_email_read_rounded,
                color: AuthPalette.gold,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'Check your inbox',
                style: TextStyle(
                  color: AuthPalette.headline,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.email != null && widget.email!.isNotEmpty
                    ? 'We sent a confirmation link to ${widget.email}. Tap the link to verify and you\'ll be signed in automatically—no need to enter your password again.'
                    : 'We sent a confirmation link to your email. Tap the link to verify and you\'ll be signed in automatically.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AuthPalette.subtext,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        if (_resendSuccess) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'New verification email sent. Check your inbox.',
                    style: TextStyle(
                      color: AuthPalette.headline,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_linkExpired) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AuthPalette.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AuthPalette.danger.withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.link_off, color: AuthPalette.danger, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'That link has expired or is invalid. Use "Resend email" below to get a new one.',
                    style: TextStyle(
                      color: AuthPalette.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_resendError != null) ...[
          const SizedBox(height: 12),
          AuthErrorBanner(message: _resendError!),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: _resending ? null : _resend,
            style: OutlinedButton.styleFrom(
              backgroundColor: AuthPalette.secondaryBtn.withValues(alpha: 0.45),
              foregroundColor: AuthPalette.secondaryBtnText,
              side: BorderSide(
                color: AuthPalette.secondaryBtnBorder.withValues(alpha: 0.7),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _resending
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AuthPalette.secondaryBtnText,
                    ),
                  )
                : const Text(
                    'Resend email',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/welcome/login'),
          child: const Text(
            'Already verified? Try signing in',
            style: TextStyle(color: AuthPalette.subtext, fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _onVerified() {
    if (_verified) return;
    setState(() => _verified = true);
  }
}
