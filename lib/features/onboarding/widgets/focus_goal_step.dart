import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/leko_colors.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';
import 'single_select_card.dart';

class FocusGoalStep extends ConsumerStatefulWidget {
  const FocusGoalStep({super.key});

  @override
  ConsumerState<FocusGoalStep> createState() => _FocusGoalStepState();
}

class _FocusGoalStepState extends ConsumerState<FocusGoalStep> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingControllerProvider);
    if (state.goalAmount > 0) {
      _amountController.text = state.goalAmount.toStringAsFixed(0);
    }
    if (state.goalTargetDate == null) {
      // Defer provider modification to after the widget tree finishes building
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(onboardingControllerProvider.notifier)
              .setGoalTargetDate(DateTime.now().add(const Duration(days: 180)));
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final selectedGoal = state.focusGoal;
    final goalAmount = state.goalAmount;
    final goalTargetDate = state.goalTargetDate;
    final controller = ref.read(onboardingControllerProvider.notifier);

    final bool canProceed = selectedGoal != null && goalAmount > 0;

    return StepScaffold(
      step: OnboardingStep.focusGoal,
      title: 'Pick one goal to start growing.',
      subtitle: 'Even small amounts build momentum. You can add more goals later.',
      canProceed: canProceed,
      onNext: () => controller.next(),
      onBack: () => controller.back(),
      child: ListView(
        children: [
          // Goal type selection
          SingleSelectCard(
            title: 'Emergency fund',
            icon: Icons.health_and_safety_rounded,
            isSelected: selectedGoal == 'Emergency Fund',
            onTap: () => controller.setFocusGoal('Emergency Fund'),
          ),
          SingleSelectCard(
            title: 'Vacation',
            icon: Icons.flight_takeoff_rounded,
            isSelected: selectedGoal == 'Vacation',
            onTap: () => controller.setFocusGoal('Vacation'),
          ),
          SingleSelectCard(
            title: 'Debt payoff',
            icon: Icons.money_off_csred_rounded,
            isSelected: selectedGoal == 'Debt Payoff',
            onTap: () => controller.setFocusGoal('Debt Payoff'),
          ),
          SingleSelectCard(
            title: 'Rent buffer',
            icon: Icons.home_rounded,
            isSelected: selectedGoal == 'Rent Buffer',
            onTap: () => controller.setFocusGoal('Rent Buffer'),
          ),
          SingleSelectCard(
            title: 'Something else',
            icon: Icons.edit_rounded,
            isSelected: selectedGoal == 'Custom',
            onTap: () => controller.setFocusGoal('Custom'),
          ),

          // Show amount + date inputs once a goal is selected
          if (selectedGoal != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: LekoColors.onboardingSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How much do you want to save?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: LekoColors.onboardingTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '\$',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: LekoColors.onboardingTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: false),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            final amount = double.tryParse(value) ?? 0.0;
                            controller.setGoalAmount(amount);
                          },
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: LekoColors.onboardingTextPrimary,
                            letterSpacing: -0.5,
                          ),
                          cursorColor: LekoColors.onboardingFill,
                          decoration: InputDecoration(
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: '1,000',
                            hintStyle: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: LekoColors.onboardingTextSecondary.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Target date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: LekoColors.onboardingTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: goalTargetDate ?? DateTime.now().add(const Duration(days: 180)),
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime(2050),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: LekoColors.onboardingFill,
                                onPrimary: LekoColors.onboardingBackground,
                                surface: LekoColors.onboardingSurface,
                                onSurface: LekoColors.onboardingTextPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        controller.setGoalTargetDate(picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: LekoColors.onboardingBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: LekoColors.onboardingTextSecondary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: LekoColors.onboardingFill,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            goalTargetDate != null
                                ? DateFormat.yMMMd().format(goalTargetDate)
                                : 'Pick a date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: goalTargetDate != null
                                  ? LekoColors.onboardingTextPrimary
                                  : LekoColors.onboardingTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can adjust these anytime in settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LekoColors.onboardingTextSecondary.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
