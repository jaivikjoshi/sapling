import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/leko_colors.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

class BalanceStep extends ConsumerStatefulWidget {
  const BalanceStep({super.key});

  @override
  ConsumerState<BalanceStep> createState() => _BalanceStepState();
}

class _BalanceStepState extends ConsumerState<BalanceStep> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentBalance = ref.read(onboardingControllerProvider).startingBalance;
    if (currentBalance > 0) {
      _controller.text = currentBalance.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBalanceChanged(String value) {
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    final balance = double.tryParse(cleanValue) ?? 0.0;
    ref.read(onboardingControllerProvider.notifier).setBalance(balance);
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(onboardingControllerProvider.select((s) => s.startingBalance));

    return StepScaffold(
      step: OnboardingStep.balance,
      title: 'Liquid Reality',
      subtitle: 'How much money is in your primary checking account right now? Don\'t include savings or credit cards.',
      nextLabel: 'Set Baseline',
      canProceed: balance > 0,
      onNext: () => ref.read(onboardingControllerProvider.notifier).next(),
      onBack: () => ref.read(onboardingControllerProvider.notifier).back(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: LekoColors.onboardingSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '\$',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: LekoColors.onboardingTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IntrinsicWidth(
                    child: TextField(
                      controller: _controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _onBalanceChanged,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: LekoColors.onboardingTextPrimary,
                        letterSpacing: -1,
                      ),
                      cursorColor: LekoColors.onboardingFill,
                      decoration: InputDecoration(
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: LekoColors.onboardingTextSecondary,
                        ).copyWith(color: LekoColors.onboardingTextSecondary.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Rough estimates are perfectly fine. You can adjust this later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: LekoColors.onboardingTextSecondary.withOpacity(0.8),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
