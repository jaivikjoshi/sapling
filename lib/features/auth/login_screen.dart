import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/auth_providers.dart';
import 'auth_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      context.go('/home');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
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
      // On mobile, browser opens then returns via deep link; auth stream will update.
      // Splash will route based on the new session.
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
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
      title: 'Welcome back',
      subtitle: 'Sign in to continue managing your money.',
      onBack: _loading ? null : () => context.go('/welcome'),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Don't have an account? ",
            style: TextStyle(color: AuthPalette.subtext, fontSize: 15),
          ),
          GestureDetector(
            onTap: _loading ? null : () => context.go('/welcome/signup'),
            child: Text(
              'Sign up',
              style: TextStyle(
                color: _loading ? AuthPalette.subtext : AuthPalette.gold,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                decoration: TextDecoration.underline,
                decorationColor:
                    _loading ? AuthPalette.subtext : AuthPalette.gold,
              ),
            ),
          ),
        ],
      ),
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
            label: 'Password',
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
              onPressed: enabled ? _signIn : null,
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
                      'Sign in',
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
              onPressed: _loading ? null : _signInWithGoogle,
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
