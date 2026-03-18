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
    });
    try {
      final client = ref.read(supabaseClientProvider);
      final email = _emailCtrl.text.trim();
      final res = await client.auth.signUp(
        email: email,
        password: _passwordCtrl.text,
        // emailRedirectTo: 'com.jaivik.leko://auth-callback', // Disabled: no email verification
      );
      if (!mounted) return;
      // Email verification disabled — pass through. Splash fetches settings and routes to onboarding or home.
      if (res.session != null) {
        context.go('/');
        return;
      }
      context.go('/');
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
        redirectTo: 'com.jaivik.leko://login-callback',
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
      child: Column(
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
