import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/leko_colors.dart';
import '../onboarding_controller.dart';

class StepScaffold extends ConsumerWidget {
  const StepScaffold({
    super.key,
    required this.step,
    required this.title,
    this.subtitle,
    required this.child,
    required this.onNext,
    this.onBack,
    this.nextLabel = 'Continue',
    this.secondaryLabel,
    this.onSecondary,
    this.canProceed = true,
    this.isLoading = false,
  });

  final OnboardingStep step;
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String nextLabel;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool canProceed;
  final bool isLoading;

  double get _progress =>
      (OnboardingStep.values.indexOf(step) + 1) /
      OnboardingStep.values.length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(
      onboardingControllerProvider.select((state) => state.error),
    );

    return Scaffold(
      backgroundColor: LekoColors.onboardingBackground,
      body: Stack(
        children: [
          const _OnboardingBackdrop(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: Row(
                    children: [
                      if (onBack != null)
                        _TopIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: onBack!,
                        )
                      else
                        const SizedBox(width: 42, height: 42),
                      const Spacer(),
                      Text(
                        'Step ${OnboardingStep.values.indexOf(step) + 1} of ${OnboardingStep.values.length}',
                        style: const TextStyle(
                          color: LekoColors.onboardingTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: LekoColors.onboardingTrack,
                      valueColor: const AlwaysStoppedAnimation(
                        LekoColors.onboardingFill,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: LekoColors.onboardingTextPrimary,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: LekoColors.onboardingTextSecondary,
                            height: 1.45,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: child,
                  ),
              ),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E1D1F).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (error != null) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFC75D53,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFFC75D53,
                                  ).withValues(alpha: 0.22),
                                ),
                              ),
                              child: Text(
                                error,
                                style: const TextStyle(
                                  color: Color(0xFFF2B6AE),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LekoColors.onboardingButton,
                              foregroundColor: LekoColors.onboardingButtonText,
                              disabledBackgroundColor:
                                  LekoColors.onboardingButton.withValues(
                                alpha: 0.28,
                              ),
                              disabledForegroundColor:
                                  LekoColors.onboardingButtonText.withValues(
                                alpha: 0.55,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            onPressed: canProceed && !isLoading ? onNext : null,
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: LekoColors.onboardingButtonText,
                                    ),
                                  )
                                : Text(
                                    nextLabel,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                          if (secondaryLabel != null && onSecondary != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    LekoColors.onboardingTextSecondary,
                              ),
                              onPressed: onSecondary,
                              child: Text(
                                secondaryLabel!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1416),
            Color(0xFF0F1A1B),
            Color(0xFF0C1718),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -30,
            child: _BackdropOrb(
              size: 180,
              color: const Color(0xFF5CBBA7).withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            top: 120,
            left: -40,
            child: _BackdropOrb(
              size: 140,
              color: const Color(0xFF2E8F88).withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Icon(
            icon,
            color: LekoColors.onboardingTextSecondary,
            size: 18,
          ),
        ),
      ),
    );
  }
}
