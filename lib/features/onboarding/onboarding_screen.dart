import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_controller.dart';
import 'widgets/activation_step.dart';
import 'widgets/balance_step.dart';
import 'widgets/bills_step.dart';
import 'widgets/focus_goal_step.dart';
import 'widgets/money_situation_step.dart';
import 'widgets/permissions_step.dart';
import 'widgets/primary_need_step.dart';
import 'widgets/protect_goal_step.dart';
import 'widgets/rhythm_step.dart';
import 'widgets/safe_to_spend_step.dart';
import 'widgets/support_style_step.dart';
import 'widgets/welcome_step.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(
      onboardingControllerProvider.select((s) => s.step),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F1A1B), // Fallback
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildStep(step),
      ),
    );
  }

  Widget _buildStep(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.welcome => const WelcomeStep(key: ValueKey('welcome')),
      OnboardingStep.primaryNeed => const PrimaryNeedStep(key: ValueKey('primaryNeed')),
      OnboardingStep.moneySituation => const MoneySituationStep(key: ValueKey('moneySituation')),
      OnboardingStep.rhythm => const RhythmStep(key: ValueKey('rhythm')),
      OnboardingStep.protectGoal => const ProtectGoalStep(key: ValueKey('protectGoal')),
      OnboardingStep.balance => const BalanceStep(key: ValueKey('balance')),
      OnboardingStep.bills => const BillsStep(key: ValueKey('bills')),
      OnboardingStep.safeToSpend => const SafeToSpendStep(key: ValueKey('safeToSpend')),
      OnboardingStep.focusGoal => const FocusGoalStep(key: ValueKey('focusGoal')),
      OnboardingStep.supportStyle => const SupportStyleStep(key: ValueKey('supportStyle')),
      OnboardingStep.permissions => const PermissionsStep(key: ValueKey('permissions')),
      OnboardingStep.activation => const ActivationStep(key: ValueKey('activation')),
    };
  }
}
