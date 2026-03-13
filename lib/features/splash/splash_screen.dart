import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/settings_model.dart';
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
      _hasNavigated = true;
      _loginRedirectTimer?.cancel();
      final user = ref.read(currentUserProvider);
      context.go(user != null ? '/home' : '/welcome');
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
    ref.watch(authStateProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Vertical gradient from warm white to a soft minty-green wash
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFBF9F6), // Sapling warm cream top
              Color(0xFFEAF6F2), // Very subtle mint midpoint
              Color(0xFFCBEDE3), // Soft green wash at bottom
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The wordmark in the same serif font used on the home page
                const Text(
                  'sapling',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B3B42), // SaplingColors.primary
                    letterSpacing: -1.0,
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
