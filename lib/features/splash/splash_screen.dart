import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/leko_colors.dart';
import '../../core/widgets/leko_mark.dart';
import '../../domain/models/settings_model.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _loginRedirectTimer;
  Timer? _fallbackTimer;
  bool _hasNavigated = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _fallbackTimer = Timer(const Duration(seconds: 15), () {
      if (_hasNavigated || !mounted) return;
      _loginRedirectTimer?.cancel();
      final user = ref.read(currentUserProvider);
      _navigateToApp(user != null);
    });
  }

  @override
  void dispose() {
    _loginRedirectTimer?.cancel();
    _fallbackTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigateToApp(bool hasSession) async {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _loginRedirectTimer?.cancel();
    _fallbackTimer?.cancel();
    if (!hasSession) {
      if (!mounted) return;
      context.go('/welcome');
      return;
    }
    UserSettings? settings;
    try {
      settings = await ref
          .read(settingsStreamProvider.future)
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      // On timeout or error (network, RLS), don't block—navigate to home.
      settings = null;
    }
    if (!mounted) return;
    if (settings != null && settings.onboardingCompleted) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  void _scheduleLoginRedirect() {
    if (_hasNavigated) return;
    _loginRedirectTimer?.cancel();
    _loginRedirectTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted || _hasNavigated) return;
      _navigateToApp(false);
    });
  }

  void _navigateFromAuthError() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _loginRedirectTimer?.cancel();
    _fallbackTimer?.cancel();
    if (!mounted) return;
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      next.whenOrNull(
        data: (event) {
          if (event.session != null) {
            _loginRedirectTimer?.cancel();
            _navigateToApp(true);
          } else {
            _scheduleLoginRedirect();
          }
        },
        error: (_, __) => _navigateFromAuthError(),
      );
    });
    // Note: ref.listen in flutter_riverpod doesn't support fireImmediately.
    // Use the authAsync.whenData check below when landing with session already present.
    final authAsync = ref.watch(authStateProvider);
    // When landing on splash with session already present (e.g. redirect from login),
    // the listen may not fire—check current value and navigate if needed.
    authAsync.whenData((event) {
      if (event.session != null && !_hasNavigated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_hasNavigated) {
            _loginRedirectTimer?.cancel();
            _navigateToApp(true);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: LekoColors.background,
      body: SizedBox.expand(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: const Color(0xFF013333),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A0E1830),
                        blurRadius: 26,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: LekoMark(size: 64, color: Color(0xFFB4B6B7)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'leko',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: LekoColors.primary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
