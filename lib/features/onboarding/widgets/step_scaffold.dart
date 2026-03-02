import 'package:flutter/material.dart';
import '../../../core/theme/sapling_colors.dart';
import '../onboarding_controller.dart';

class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onNext,
    this.onBack,
    this.nextLabel = 'Continue',
    this.canProceed = true,
    this.isLoading = false,
  });

  final OnboardingStep step;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String nextLabel;
  final bool canProceed;
  final bool isLoading;

  double get _progress =>
      (OnboardingStep.values.indexOf(step) + 1) /
      OnboardingStep.values.length;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 4,
                backgroundColor: SaplingColors.divider,
                valueColor: const AlwaysStoppedAnimation(SaplingColors.secondary),
              ),
            ),
            const SizedBox(height: 32),
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: SaplingColors.primary,
            )),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: SaplingColors.textSecondary,
            )),
            const SizedBox(height: 32),
            Expanded(child: child),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: canProceed && !isLoading ? onNext : null,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(nextLabel),
            ),
            if (onBack != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onBack, child: const Text('Back')),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
