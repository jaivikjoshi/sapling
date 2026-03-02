import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/settings_providers.dart';
import '../../core/theme/sapling_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final settings = await ref.read(settingsStreamProvider.future);
    if (!mounted) return;
    if (settings.onboardingCompleted) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
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
