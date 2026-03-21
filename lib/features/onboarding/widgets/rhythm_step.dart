import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/leko_colors.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';
import 'single_select_card.dart';

class RhythmStep extends ConsumerStatefulWidget {
  const RhythmStep({super.key});

  @override
  ConsumerState<RhythmStep> createState() => _RhythmStepState();
}

class _RhythmStepState extends ConsumerState<RhythmStep> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingControllerProvider);
    if (state.incomeAmount > 0) {
      _amountController.text = state.incomeAmount.toStringAsFixed(0);
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
    final selectedRhythm = state.rhythm;
    final incomeAmount = state.incomeAmount;
    final controller = ref.read(onboardingControllerProvider.notifier);

    // If a rhythm is selected, but it's not irregular, require an amount.
    // If it is irregular, amount is theoretically optional but better to ask for an average.
    final bool canProceed = selectedRhythm != null && incomeAmount > 0;

    return StepScaffold(
      step: OnboardingStep.rhythm,
      title: 'How often do you get paid?',
      subtitle: 'This helps Léko plan your spending around real life, not just monthly averages.',
      canProceed: canProceed,
      onNext: () => controller.next(),
      onBack: () => controller.back(),
      child: ListView(
        children: [
          SingleSelectCard(
            title: 'Weekly',
            isSelected: selectedRhythm == IncomeRhythm.weekly,
            onTap: () => controller.setRhythm(IncomeRhythm.weekly),
          ),
          SingleSelectCard(
            title: 'Biweekly',
            isSelected: selectedRhythm == IncomeRhythm.biweekly,
            onTap: () => controller.setRhythm(IncomeRhythm.biweekly),
          ),
          SingleSelectCard(
            title: 'Twice a month',
            isSelected: selectedRhythm == IncomeRhythm.twiceAMonth,
            onTap: () => controller.setRhythm(IncomeRhythm.twiceAMonth),
          ),
          SingleSelectCard(
            title: 'Monthly',
            isSelected: selectedRhythm == IncomeRhythm.monthly,
            onTap: () => controller.setRhythm(IncomeRhythm.monthly),
          ),
          SingleSelectCard(
            title: 'Irregular / freelance',
            isSelected: selectedRhythm == IncomeRhythm.irregular,
            onTap: () => controller.setRhythm(IncomeRhythm.irregular),
          ),

          if (selectedRhythm != null) ...[
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
                    selectedRhythm == IncomeRhythm.irregular 
                        ? 'Roughly how much on average?' 
                        : 'How much per paycheck?',
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
                            controller.setIncomeAmount(amount);
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
                            hintText: '2,500',
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
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rough estimates are fine. You can change this later.',
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
