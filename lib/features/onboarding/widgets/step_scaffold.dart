import 'package:flutter/material.dart';
import '../../../core/theme/leko_colors.dart';
import '../onboarding_controller.dart';

class StepScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LekoColors.onboardingBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: LekoColors.onboardingTextSecondary, size: 20),
                onPressed: onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 3,
                  backgroundColor: LekoColors.onboardingTrack,
                  valueColor: const AlwaysStoppedAnimation(LekoColors.onboardingFill),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: LekoColors.onboardingTextPrimary,
                      letterSpacing: -0.5,
                      height: 1.2,
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
                        height: 1.4,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: child,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LekoColors.onboardingButton,
                      foregroundColor: LekoColors.onboardingButtonText,
                      disabledBackgroundColor: LekoColors.onboardingButton.withOpacity(0.3),
                      disabledForegroundColor: LekoColors.onboardingButtonText.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: canProceed && !isLoading ? onNext : null,
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: LekoColors.onboardingButtonText),
                          )
                        : Text(
                            nextLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  if (secondaryLabel != null && onSecondary != null) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: LekoColors.onboardingTextSecondary,
                      ),
                      onPressed: onSecondary,
                      child: Text(
                        secondaryLabel!,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
