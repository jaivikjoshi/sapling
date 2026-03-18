import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/leko_colors.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

class BillsStep extends ConsumerWidget {
  const BillsStep({super.key});

  final List<Map<String, dynamic>> _commonBills = const [
    {'name': 'Rent/Mortgage', 'icon': Icons.home_rounded},
    {'name': 'Groceries', 'icon': Icons.shopping_basket_rounded},
    {'name': 'Car/Transport', 'icon': Icons.directions_car_rounded},
    {'name': 'Utilities', 'icon': Icons.bolt_rounded},
    {'name': 'Internet/Phone', 'icon': Icons.wifi_rounded},
    {'name': 'Insurance', 'icon': Icons.health_and_safety_rounded},
    {'name': 'Subscriptions', 'icon': Icons.subscriptions_rounded},
    {'name': 'Debt/Loans', 'icon': Icons.account_balance_rounded},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBills = ref.watch(onboardingControllerProvider.select((s) => s.selectedBills));
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.bills,
      title: 'The Horizon',
      subtitle: 'Select the major categories you want Léko to protect funds for. We\'ll dial in the exact amounts later.',
      nextLabel: selectedBills.isEmpty ? 'Skip for now' : 'Protect ${selectedBills.length} Bill${selectedBills.length == 1 ? '' : 's'}',
      onNext: () => controller.next(),
      onBack: () => controller.back(),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _commonBills.length,
        itemBuilder: (context, index) {
          final bill = _commonBills[index];
          final billName = bill['name'] as String;
          final isSelected = selectedBills.contains(billName);
          
          return GestureDetector(
            onTap: () => controller.toggleBill(billName),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? LekoColors.onboardingFill.withOpacity(0.15) : LekoColors.onboardingSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? LekoColors.onboardingFill : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    bill['icon'] as IconData,
                    size: 32,
                    color: isSelected ? LekoColors.onboardingFill : LekoColors.onboardingTextSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    billName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? LekoColors.onboardingTextPrimary : LekoColors.onboardingTextPrimary.withOpacity(0.9),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
