import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/auth_providers.dart';
import 'auth_shell.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = false;
    });
    try {
      final client = ref.read(supabaseClientProvider);
      final res = await client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      // If session exists, email confirmation is disabled — go to app.
      if (res.session != null) {
        context.go('/home');
        return;
      }
      // Email confirmation required
      if (mounted) {
        setState(() {
          _loading = false;
          _success = true;
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.jaivik.sapling://login-callback',
      );
      // After OAuth completes, auth stream will update and splash will route.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        _emailCtrl.text.isNotEmpty &&
        _passwordCtrl.text.length >= 6 &&
        !_loading;

    return AuthScaffold(
      title: 'Create account',
      subtitle: 'Start your journey to better budgeting.',
      onBack: _loading ? null : () => context.go('/welcome'),
      child: _success
          ? Column(
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
                  child: const Column(
                    children: [
                      Icon(
                        Icons.mark_email_read_rounded,
                        color: AuthPalette.gold,
                        size: 42,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Check your email',
                        style: TextStyle(
                          color: AuthPalette.headline,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'We sent a confirmation link to your email address. Please verify your account, then sign in.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AuthPalette.subtext,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: () => context.go('/welcome/login'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AuthPalette.primaryBtn,
                      foregroundColor: AuthPalette.primaryBtnText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Return to sign in',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _passwordCtrl,
                  label: 'Password (min 6 chars)',
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  AuthErrorBanner(message: _error!),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: enabled ? _signUp : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AuthPalette.primaryBtn,
                      disabledBackgroundColor:
                          AuthPalette.primaryBtn.withValues(alpha: 0.35),
                      foregroundColor: AuthPalette.primaryBtnText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AuthPalette.primaryBtnText,
                            ),
                          )
                        : const Text(
                            'Create account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const AuthDivider(),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _signUpWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          AuthPalette.secondaryBtn.withValues(alpha: 0.45),
                      foregroundColor: AuthPalette.secondaryBtnText,
                      side: BorderSide(
                        color: AuthPalette.secondaryBtnBorder.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
