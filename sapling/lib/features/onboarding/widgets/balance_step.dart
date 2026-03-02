import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final balance = ref.read(onboardingControllerProvider).startingBalance;
    if (balance != 0) _controller.text = balance.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(onboardingControllerProvider.notifier);
    final currency = ref.watch(
      onboardingControllerProvider.select((s) => s.currency),
    );
    final symbol = currency.name.toUpperCase();

    return StepScaffold(
      step: OnboardingStep.balance,
      title: 'Starting balance',
      subtitle:
          'Enter your current chequing account balance in $symbol.',
      onNext: () {
        final value = double.tryParse(_controller.text) ?? 0;
        ctrl.setBalance(value);
        ctrl.next();
      },
      onBack: () => ctrl.back(),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        style: Theme.of(context).textTheme.headlineMedium,
        decoration: InputDecoration(
          prefixText: '\$ ',
          hintText: '0.00',
          prefixStyle: Theme.of(context).textTheme.headlineMedium,
        ),
        autofocus: true,
      ),
    );
  }
}
