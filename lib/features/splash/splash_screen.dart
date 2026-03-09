import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/theme/sapling_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _loginRedirectTimer;
  bool _hasNavigated = false;

  @override
  void dispose() {
    _loginRedirectTimer?.cancel();
    super.dispose();
  }

  Future<void> _navigateToApp(bool hasSession) async {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _loginRedirectTimer?.cancel();
    if (!hasSession) {
      if (!mounted) return;
      context.go('/login');
      return;
    }
    final settings = await ref.read(settingsStreamProvider.future);
    if (!mounted) return;
    if (settings.onboardingCompleted) {
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
      );
    });
    ref.watch(authStateProvider);

    return const Scaffold(
      backgroundColor: SaplingColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco, size: 64, color: SaplingColors.secondary),
            SizedBox(height: 16),
            Text(
              'Sapling',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: SaplingColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

