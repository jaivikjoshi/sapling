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

  int get _stepIndex {
    final index = OnboardingController.orderedSteps.indexOf(step);
    return index < 0 ? 0 : index;
  }

  double get _progress =>
      (_stepIndex + 1) / OnboardingController.orderedSteps.length;

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
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
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
                        'Step ${_stepIndex + 1} of ${OnboardingController.orderedSteps.length}',
                        style: const TextStyle(
                          color: LekoColors.onboardingTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
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
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: LekoColors.onboardingTextPrimary,
                      letterSpacing: 0,
                      height: 1.1,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: LekoColors.onboardingTextSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: child,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 18),
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
                            ).withValues(alpha: 0.10),
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
                              color: Color(0xFF9D4038),
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
                          disabledBackgroundColor: LekoColors.onboardingButton
                              .withValues(alpha: 0.28),
                          disabledForegroundColor: LekoColors
                              .onboardingButtonText
                              .withValues(alpha: 0.55),
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: canProceed && !isLoading ? onNext : null,
                        child:
                            isLoading
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
                                    letterSpacing: 0.2,
                                  ),
                                ),
                      ),
                      if (secondaryLabel != null && onSecondary != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: LekoColors.textSecondary,
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
    return const ColoredBox(
      color: LekoColors.onboardingBackground,
      child: SizedBox.expand(),
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
            color: LekoColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LekoColors.divider),
          ),
          child: Icon(icon, color: LekoColors.primary, size: 18),
        ),
      ),
    );
  }
}
