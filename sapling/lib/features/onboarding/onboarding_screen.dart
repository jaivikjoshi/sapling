import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_controller.dart';
import 'widgets/currency_step.dart';
import 'widgets/balance_step.dart';
import 'widgets/income_step.dart';
import 'widgets/rollover_step.dart';
import 'widgets/baseline_step.dart';
import 'widgets/notifications_step.dart';
import 'widgets/completion_step.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(
      onboardingControllerProvider.select((s) => s.step),
    );

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildStep(step),
      ),
    );
  }

  Widget _buildStep(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.currency => const CurrencyStep(key: ValueKey('currency')),
      OnboardingStep.balance => const BalanceStep(key: ValueKey('balance')),
      OnboardingStep.income => const IncomeStep(key: ValueKey('income')),
      OnboardingStep.rollover => const RolloverStep(key: ValueKey('rollover')),
      OnboardingStep.baseline => const BaselineStep(key: ValueKey('baseline')),
      OnboardingStep.notifications => const NotificationsStep(key: ValueKey('notifs')),
      OnboardingStep.completion => const CompletionStep(key: ValueKey('done')),
    };
  }
}
