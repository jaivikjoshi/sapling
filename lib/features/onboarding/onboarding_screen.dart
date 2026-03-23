import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/models/enums.dart';
import 'onboarding_controller.dart';
import 'widgets/step_scaffold.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(
      onboardingControllerProvider.select((state) => state.step),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey(step),
        child: switch (step) {
          OnboardingStep.welcome => const _WelcomeStep(),
          OnboardingStep.intent => const _IntentStep(),
          OnboardingStep.currency => const _CurrencyStep(),
          OnboardingStep.balance => const _BalanceStep(),
          OnboardingStep.goal => const _GoalStep(),
          OnboardingStep.income => const _IncomeStep(),
          OnboardingStep.rollover => const _RolloverStep(),
          OnboardingStep.bills => const _BillsStep(),
          OnboardingStep.baseline => const _BaselineStep(),
          OnboardingStep.notifications => const _NotificationsStep(),
          OnboardingStep.recap => const _RecapStep(),
        },
      ),
    );
  }
}

class _WelcomeStep extends ConsumerStatefulWidget {
  const _WelcomeStep();

  @override
  ConsumerState<_WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends ConsumerState<_WelcomeStep> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final name = ref.read(onboardingControllerProvider).name;
    _nameCtrl = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.welcome,
      title: 'What should we call you?',
      subtitle:
          'We’ll use this to personalize your experience and make Leko feel more like a calm guide than a blank tool.',
      nextLabel: 'Continue',
      onNext: () => controller.next(),
      canProceed: state.name.trim().isNotEmpty,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            _NameIntroCard(name: state.name),
            SizedBox(height: 24),
            _PremiumField(
              label: 'First name',
              hint: 'Jaivik',
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              onChanged: controller.setName,
            ),
            SizedBox(height: 14),
            _QuietHelperCard(
              icon: Icons.favorite_border_rounded,
              text:
                  'First name is perfect. This helps us personalize greetings, your recap, and your profile.',
            ),
            SizedBox(height: 14),
            _WarmBullet(
              title: 'A lighter setup, not a long form',
              subtitle:
                  'After this, we only ask for the details Leko actually needs to guide your spending well.',
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentStep extends ConsumerWidget {
  const _IntentStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.intent,
      title: 'What are you here for right now?',
      subtitle:
          'This helps Leko frame your setup with the right tone and defaults.',
      onBack: controller.back,
      onNext: () => controller.next(),
      canProceed: state.intent != null,
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (final option in OnboardingIntent.values)
              _ChoiceCard(
                title: _intentTitle(option),
                description: _intentDescription(option),
                icon: _intentIcon(option),
                selected: state.intent == option,
                onTap: () => controller.setIntent(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyStep extends ConsumerWidget {
  const _CurrencyStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.currency,
      title: 'Which currency should Leko use?',
      subtitle:
          'You can change this later, but picking it now keeps every amount consistent from the start.',
      onBack: controller.back,
      onNext: () => controller.next(),
      canProceed: state.baseCurrency != null,
      child: Column(
        children: [
          _LargeChoiceTile(
            title: 'Canadian Dollar',
            trailing: 'CAD',
            subtitle: 'Best if your day-to-day spending is in Canada.',
            selected: state.baseCurrency == Currency.cad,
            onTap: () => controller.setBaseCurrency(Currency.cad),
          ),
          const SizedBox(height: 14),
          _LargeChoiceTile(
            title: 'US Dollar',
            trailing: 'USD',
            subtitle: 'Best if your income and spending mainly happen in the US.',
            selected: state.baseCurrency == Currency.usd,
            onTap: () => controller.setBaseCurrency(Currency.usd),
          ),
        ],
      ),
    );
  }
}

class _BalanceStep extends ConsumerStatefulWidget {
  const _BalanceStep();

  @override
  ConsumerState<_BalanceStep> createState() => _BalanceStepState();
}

class _BalanceStepState extends ConsumerState<_BalanceStep> {
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    final amount = ref.read(onboardingControllerProvider).currentBalance;
    _amountCtrl = TextEditingController(
      text: amount != null && amount > 0 ? amount.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final currency = ref.watch(
      onboardingControllerProvider.select((state) => state.baseCurrency),
    );

    return StepScaffold(
      step: OnboardingStep.balance,
      title: 'What’s in chequing right now?',
      subtitle:
          'This gives Leko the starting point it needs to make today’s guidance feel grounded immediately.',
      onBack: controller.back,
      onNext: () => controller.next(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _AmountEntryCard(
              currencyCode: (currency ?? Currency.cad).name.toUpperCase(),
              controller: _amountCtrl,
              hint: '0.00',
              onChanged: (value) => controller.setCurrentBalance(
                double.tryParse(value.replaceAll(',', '').trim()),
              ),
            ),
            const SizedBox(height: 18),
            const _QuietHelperCard(
              icon: Icons.shield_moon_rounded,
              text:
                  'You’re not locking yourself in. This just helps your first spend plan feel realistic instead of blank.',
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalStep extends ConsumerStatefulWidget {
  const _GoalStep();

  @override
  ConsumerState<_GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends ConsumerState<_GoalStep> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingControllerProvider);
    _nameCtrl = TextEditingController(text: state.goalName);
    _amountCtrl = TextEditingController(
      text: state.goalAmount != null ? state.goalAmount!.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.goal,
      title: 'Create your first goal',
      subtitle:
          'This can be simple. If you add one now, Leko will use it as your main goal for planning.',
      onBack: controller.back,
      onNext: () => controller.next(),
      secondaryLabel: 'Skip for now',
      onSecondary: controller.skipGoal,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ToggleTile(
              title: 'Set a goal during onboarding',
              subtitle: 'Recommended if you want Home to feel more personal right away.',
              value: state.goalEnabled,
              onChanged: controller.setGoalEnabled,
            ),
            if (state.goalEnabled) ...[
              const SizedBox(height: 18),
              _PremiumField(
                label: 'Goal name',
                hint: 'Emergency fund, trip, buffer...',
                controller: _nameCtrl,
                onChanged: controller.setGoalName,
              ),
              const SizedBox(height: 14),
              _PremiumField(
                label: 'Target amount',
                hint: '2500',
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixText: '\$ ',
                onChanged: (value) => controller.setGoalAmount(
                  double.tryParse(value.replaceAll(',', '').trim()),
                ),
              ),
              const SizedBox(height: 14),
              _DatePickerTile(
                label: 'Target date',
                value: state.goalTargetDate,
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        state.goalTargetDate ?? now.add(const Duration(days: 90)),
                    firstDate: now.add(const Duration(days: 1)),
                    lastDate: DateTime(now.year + 10),
                  );
                  if (picked != null) controller.setGoalTargetDate(picked);
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Saving style',
                style: TextStyle(
                  color: _OnboardingPalette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _ChoiceCard(
                title: 'Easy',
                description: 'More breathing room day to day.',
                icon: Icons.air_rounded,
                selected: state.goalSavingStyle == SavingStyle.easy,
                onTap: () => controller.setGoalSavingStyle(SavingStyle.easy),
              ),
              _ChoiceCard(
                title: 'Natural',
                description: 'Balanced guidance for everyday life.',
                icon: Icons.balance_rounded,
                selected: state.goalSavingStyle == SavingStyle.natural,
                onTap: () => controller.setGoalSavingStyle(SavingStyle.natural),
              ),
              _ChoiceCard(
                title: 'Aggressive',
                description: 'Tighter daily spend, faster goal protection.',
                icon: Icons.trending_up_rounded,
                selected: state.goalSavingStyle == SavingStyle.aggressive,
                onTap: () => controller.setGoalSavingStyle(SavingStyle.aggressive),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IncomeStep extends ConsumerStatefulWidget {
  const _IncomeStep();

  @override
  ConsumerState<_IncomeStep> createState() => _IncomeStepState();
}

class _IncomeStepState extends ConsumerState<_IncomeStep> {
  late final TextEditingController _recurringNameCtrl;
  late final TextEditingController _expectedAmountCtrl;
  late final TextEditingController _oneTimeAmountCtrl;
  late final TextEditingController _oneTimeSourceCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingControllerProvider);
    _recurringNameCtrl = TextEditingController(
      text: state.recurringIncome?.name ?? '',
    );
    _expectedAmountCtrl = TextEditingController(
      text: state.recurringIncome?.expectedAmount != null
          ? state.recurringIncome!.expectedAmount!.toStringAsFixed(2)
          : '',
    );
    _oneTimeAmountCtrl = TextEditingController(
      text: state.oneTimeIncomeAmount != null
          ? state.oneTimeIncomeAmount!.toStringAsFixed(2)
          : '',
    );
    _oneTimeSourceCtrl = TextEditingController(text: state.oneTimeIncomeSource);
  }

  @override
  void dispose() {
    _recurringNameCtrl.dispose();
    _expectedAmountCtrl.dispose();
    _oneTimeAmountCtrl.dispose();
    _oneTimeSourceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final recurring = state.recurringIncome;

    return StepScaffold(
      step: OnboardingStep.income,
      title: 'Add income to shape your rhythm',
      subtitle:
          'Recurring income helps Leko plan around payday. A one-time income can still give your starting balance a boost.',
      onBack: controller.back,
      onNext: () => controller.next(),
      secondaryLabel: 'Skip for now',
      onSecondary: () {
        controller.setHasRecurringIncome(false);
        controller.setHasOneTimeIncome(false);
        controller.next();
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            _ToggleTile(
              title: 'Add recurring income',
              subtitle: 'Useful if you want Leko to plan around payday.',
              value: state.hasRecurringIncome,
              onChanged: controller.setHasRecurringIncome,
            ),
            if (state.hasRecurringIncome) ...[
              const SizedBox(height: 16),
              _PremiumField(
                label: 'Income name',
                hint: 'Paycheque, freelance retainer...',
                controller: _recurringNameCtrl,
                onChanged: (value) => controller.updateRecurringIncome(name: value),
              ),
              const SizedBox(height: 14),
              _SelectorWrap(
                title: 'Frequency',
                options: IncomeFrequency.values
                    .map((frequency) => _ChipOption<IncomeFrequency>(
                          value: frequency,
                          label: _incomeFrequencyLabel(frequency),
                        ))
                    .toList(),
                selected: recurring?.frequency,
                onSelected: (value) =>
                    controller.updateRecurringIncome(frequency: value),
              ),
              const SizedBox(height: 14),
              _DatePickerTile(
                label: 'Next payday',
                value: recurring?.nextPaydayDate,
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        recurring?.nextPaydayDate ?? now.add(const Duration(days: 14)),
                    firstDate: now,
                    lastDate: DateTime(now.year + 5),
                  );
                  if (picked != null) {
                    controller.updateRecurringIncome(nextPaydayDate: () => picked);
                  }
                },
              ),
              const SizedBox(height: 14),
              _SelectorWrap(
                title: 'Default payday behavior',
                options: const [
                  _ChipOption(
                    value: PaydayBehavior.confirmActualOnPayday,
                    label: 'Confirm actual',
                  ),
                  _ChipOption(
                    value: PaydayBehavior.autoPostExpected,
                    label: 'Auto-post expected',
                  ),
                ],
                selected: recurring?.paydayBehavior,
                onSelected: (value) =>
                    controller.updateRecurringIncome(paydayBehavior: value),
              ),
              const SizedBox(height: 14),
              _PremiumField(
                label: 'Expected amount',
                hint: 'Only required for auto-post expected',
                controller: _expectedAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixText: '\$ ',
                onChanged: (value) => controller.updateRecurringIncome(
                  expectedAmount: () =>
                      double.tryParse(value.replaceAll(',', '').trim()),
                ),
              ),
            ],
            const SizedBox(height: 18),
            _ToggleTile(
              title: 'Add one-time income',
              subtitle: 'Optional if you already know about a deposit or incoming payment.',
              value: state.hasOneTimeIncome,
              onChanged: controller.setHasOneTimeIncome,
            ),
            if (state.hasOneTimeIncome) ...[
              const SizedBox(height: 16),
              _PremiumField(
                label: 'Amount',
                hint: '500',
                controller: _oneTimeAmountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixText: '\$ ',
                onChanged: (value) => controller.setOneTimeIncomeAmount(
                  double.tryParse(value.replaceAll(',', '').trim()),
                ),
              ),
              const SizedBox(height: 14),
              _PremiumField(
                label: 'Source',
                hint: 'Bonus, refund, side project...',
                controller: _oneTimeSourceCtrl,
                onChanged: controller.setOneTimeIncomeSource,
              ),
              const SizedBox(height: 14),
              _DatePickerTile(
                label: 'Arrival date',
                value: state.oneTimeIncomeDate,
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: state.oneTimeIncomeDate ?? now,
                    firstDate: now.subtract(const Duration(days: 30)),
                    lastDate: DateTime(now.year + 2),
                  );
                  if (picked != null) controller.setOneTimeIncomeDate(picked);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RolloverStep extends ConsumerWidget {
  const _RolloverStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final recurring = state.recurringIncome;

    return StepScaffold(
      step: OnboardingStep.rollover,
      title: 'How should Leko reset your allowance?',
      subtitle:
          'Choose the rhythm that should guide your day-to-day spending ceiling.',
      onBack: controller.back,
      onNext: () => controller.next(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _ChoiceCard(
              title: 'Monthly reset',
              description: 'Simple, clean, and predictable month to month.',
              icon: Icons.calendar_month_rounded,
              selected: state.rolloverResetType == RolloverResetType.monthly,
              onTap: () => controller.setRolloverResetType(RolloverResetType.monthly),
            ),
            _ChoiceCard(
              title: 'Payday-based reset',
              description: 'Best if your spending rhythm revolves around paycheques.',
              icon: Icons.event_repeat_rounded,
              selected: state.rolloverResetType == RolloverResetType.paydayBased,
              onTap: () =>
                  controller.setRolloverResetType(RolloverResetType.paydayBased),
            ),
            if (state.rolloverResetType == RolloverResetType.paydayBased) ...[
              const SizedBox(height: 12),
              if (recurring == null)
                const _QuietHelperCard(
                  icon: Icons.info_outline_rounded,
                  text:
                      'Add a recurring income first if you want payday-based planning. Otherwise choose monthly reset.',
                )
              else
                _AnchorChoiceTile(
                  title: 'Use ${recurring.name.isEmpty ? 'your recurring income' : recurring.name} as the Payday Anchor',
                  subtitle:
                      'This tells Leko which schedule should anchor spend planning.',
                  selected: state.paydayAnchorDraftId == recurring.id,
                  onTap: () => controller.setPaydayAnchorDraftId(recurring.id),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BillsStep extends ConsumerStatefulWidget {
  const _BillsStep();

  @override
  ConsumerState<_BillsStep> createState() => _BillsStepState();
}

class _BillsStepState extends ConsumerState<_BillsStep> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  BillFrequency _frequency = BillFrequency.monthly;
  DateTime? _nextDueDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _amountCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _addBill(OnboardingController controller) {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '').trim());
    if (name.isEmpty || amount == null || amount <= 0 || _nextDueDate == null) {
      return;
    }
    controller.addBillDraft(
      name: name,
      amount: amount,
      frequency: _frequency,
      nextDueDate: _nextDueDate!,
    );
    _nameCtrl.clear();
    _amountCtrl.clear();
    setState(() {
      _frequency = BillFrequency.monthly;
      _nextDueDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.bills,
      title: 'Add bills you already know about',
      subtitle:
          'This is optional, but even one or two bills makes Home feel smarter right away.',
      onBack: controller.back,
      onNext: () => controller.next(),
      secondaryLabel: 'Skip for now',
      onSecondary: controller.skipBills,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PremiumField(
              label: 'Bill name',
              hint: 'Rent, phone, internet...',
              controller: _nameCtrl,
            ),
            const SizedBox(height: 14),
            _PremiumField(
              label: 'Amount',
              hint: '120',
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixText: '\$ ',
            ),
            const SizedBox(height: 14),
            _SelectorWrap(
              title: 'Frequency',
              options: BillFrequency.values
                  .where((frequency) => [
                        BillFrequency.weekly,
                        BillFrequency.biweekly,
                        BillFrequency.monthly,
                        BillFrequency.yearly,
                      ].contains(frequency))
                  .map((frequency) => _ChipOption<BillFrequency>(
                        value: frequency,
                        label: _billFrequencyLabel(frequency),
                      ))
                  .toList(),
              selected: _frequency,
              onSelected: (value) => setState(() => _frequency = value),
            ),
            const SizedBox(height: 14),
            _DatePickerTile(
              label: 'Next due date',
              value: _nextDueDate,
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _nextDueDate ?? now.add(const Duration(days: 14)),
                  firstDate: now,
                  lastDate: DateTime(now.year + 5),
                );
                if (picked != null) {
                  setState(() => _nextDueDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _addBill(controller),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _OnboardingPalette.textPrimary,
                  side: BorderSide(
                    color: _OnboardingPalette.teal.withValues(alpha: 0.45),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Add bill',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (state.billDrafts.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Added bills',
                style: TextStyle(
                  color: _OnboardingPalette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              for (final bill in state.billDrafts)
                _AddedBillRow(
                  bill: bill,
                  onRemove: () => controller.removeBillDraft(bill.id),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BaselineStep extends ConsumerWidget {
  const _BaselineStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.baseline,
      title: 'How responsive should your baseline feel?',
      subtitle:
          'This shapes how much recent spending history should influence your guidance.',
      onBack: controller.back,
      onNext: () => controller.next(),
      child: Column(
        children: [
          _ChoiceCard(
            title: '30 days',
            description: 'More responsive. Good if your spending changes quickly.',
            icon: Icons.speed_rounded,
            selected: state.spendingBaselineDays == 30,
            onTap: () => controller.setSpendingBaselineDays(30),
          ),
          _ChoiceCard(
            title: '60 days',
            description: 'Balanced. A strong default for most people.',
            icon: Icons.tune_rounded,
            selected: state.spendingBaselineDays == 60,
            onTap: () => controller.setSpendingBaselineDays(60),
          ),
          _ChoiceCard(
            title: '90 days',
            description: 'Smoother. Better if you want guidance to feel less jumpy.',
            icon: Icons.waves_rounded,
            selected: state.spendingBaselineDays == 90,
            onTap: () => controller.setSpendingBaselineDays(90),
          ),
        ],
      ),
    );
  }
}

class _NotificationsStep extends ConsumerWidget {
  const _NotificationsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.notifications,
      title: 'Let Leko nudge you at the right moments',
      subtitle:
          'Useful for payday reminders, bill alerts, overspend warnings, and your nightly closeout check-in.',
      onBack: controller.back,
      onNext: () async {
        await controller.requestNotifications();
        await controller.next();
      },
      nextLabel: 'Enable notifications',
      secondaryLabel: 'Maybe later',
      onSecondary: () {
        controller.skipNotifications();
        controller.next();
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const _NotificationArtCard(),
            const SizedBox(height: 20),
            const _QuietHelperCard(
              icon: Icons.notifications_active_rounded,
              text:
                  'We only ask the system for permission after you tap enable. You can always change this later.',
            ),
            if (state.notificationPreference == NotificationPreference.enable)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  state.notificationsGranted
                      ? 'Notifications are on.'
                      : 'Permission wasn’t granted, but you can still continue and change it later.',
                  style: TextStyle(
                    color: state.notificationsGranted
                        ? _OnboardingPalette.tealSoft
                        : _OnboardingPalette.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecapStep extends ConsumerWidget {
  const _RecapStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return StepScaffold(
      step: OnboardingStep.recap,
      title: state.name.trim().isEmpty
          ? 'You’re set. Let’s build your daily spend plan.'
          : 'You’re set, ${_firstName(state.name)}.',
      subtitle:
          'Leko has enough context now to guide you calmly from the moment you land on Home.',
      onBack: controller.back,
      onNext: () async {
        final success = await controller.complete();
        if (success && context.mounted) {
          context.go('/');
        }
      },
      nextLabel: 'Open Leko',
      isLoading: state.isSubmitting,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RecapTile(
              label: 'Name',
              value: state.name.trim().isEmpty ? 'Not set' : state.name.trim(),
            ),
            _RecapTile(
              label: 'Currency',
              value: (state.baseCurrency ?? Currency.cad).name.toUpperCase(),
            ),
            _RecapTile(
              label: 'Current balance',
              value: state.currentBalance != null
                  ? '\$${state.currentBalance!.toStringAsFixed(2)}'
                  : 'Not set',
            ),
            _RecapTile(
              label: 'Main goal',
              value: state.goalEnabled && state.hasGoalInput
                  ? state.goalName
                  : 'Skipping goals for now',
            ),
            _RecapTile(
              label: 'Income setup',
              value: [
                if (state.hasRecurringIncome) 'Recurring income',
                if (state.hasOneTimeIncome) 'One-time income',
                if (!state.hasRecurringIncome && !state.hasOneTimeIncome) 'Skipped for now',
              ].join(' + '),
            ),
            _RecapTile(
              label: 'Rollover style',
              value: state.rolloverResetType == RolloverResetType.monthly
                  ? 'Monthly reset'
                  : 'Payday-based reset',
            ),
            _RecapTile(
              label: 'Baseline',
              value: '${state.spendingBaselineDays} day window',
            ),
            _RecapTile(
              label: 'Notifications',
              value: switch (state.notificationPreference) {
                NotificationPreference.enable when state.notificationsGranted =>
                  'Enabled',
                NotificationPreference.enable => 'Not granted yet',
                NotificationPreference.later => 'Maybe later',
                null => 'Maybe later',
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WarmBullet extends StatelessWidget {
  const _WarmBullet({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: _OnboardingPalette.tealSoft,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _OnboardingPalette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _OnboardingPalette.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationArtCard extends StatelessWidget {
  const _NotificationArtCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _OnboardingPalette.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _OnboardingPalette.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 180,
            height: 300,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0F8),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: 18,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 62,
                      height: 20,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF111217),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 74,
                  left: 18,
                  right: 18,
                  child: Column(
                    children: [
                      const Text(
                        'Nightly closeout',
                        style: TextStyle(
                          color: Color(0xFF2D3346),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(0xFFDFF6F0),
                              child: Icon(
                                Icons.notifications_active_rounded,
                                size: 16,
                                color: _OnboardingPalette.teal,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You stayed within today\'s pace. Want to close out the day?',
                                style: TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: selected
                  ? _OnboardingPalette.surfaceSelected
                  : _OnboardingPalette.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected
                    ? _OnboardingPalette.tealSoft.withValues(alpha: 0.7)
                    : _OnboardingPalette.outline,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected
                        ? _OnboardingPalette.tealSoft.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? _OnboardingPalette.tealSoft
                        : _OnboardingPalette.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _OnboardingPalette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: _OnboardingPalette.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? _OnboardingPalette.tealSoft
                      : _OnboardingPalette.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LargeChoiceTile extends StatelessWidget {
  const _LargeChoiceTile({
    required this.title,
    required this.trailing,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String trailing;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: selected
                ? _OnboardingPalette.surfaceSelected
                : _OnboardingPalette.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected
                  ? _OnboardingPalette.tealSoft.withValues(alpha: 0.7)
                  : _OnboardingPalette.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _OnboardingPalette.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _OnboardingPalette.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  trailing,
                  style: const TextStyle(
                    color: _OnboardingPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountEntryCard extends StatelessWidget {
  const _AmountEntryCard({
    required this.currencyCode,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final String currencyCode;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _OnboardingPalette.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _OnboardingPalette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Current chequing balance',
                style: TextStyle(
                  color: _OnboardingPalette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                currencyCode,
                style: const TextStyle(
                  color: _OnboardingPalette.tealSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onChanged,
            style: const TextStyle(
              color: _OnboardingPalette.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.4,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: _OnboardingPalette.textMuted,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.4,
              ),
              prefixText: '\$ ',
              prefixStyle: const TextStyle(
                color: _OnboardingPalette.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.w700,
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumField extends StatelessWidget {
  const _PremiumField({
    required this.label,
    required this.hint,
    required this.controller,
    this.onChanged,
    this.keyboardType,
    this.prefixText,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final String? prefixText;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _OnboardingPalette.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          style: const TextStyle(
            color: _OnboardingPalette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              color: _OnboardingPalette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            hintStyle: const TextStyle(
              color: _OnboardingPalette.textMuted,
            ),
            filled: true,
            fillColor: _OnboardingPalette.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: _OnboardingPalette.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: _OnboardingPalette.tealSoft.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _OnboardingPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _OnboardingPalette.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _OnboardingPalette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _OnboardingPalette.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch.adaptive(
            value: value,
            activeColor: _OnboardingPalette.tealSoft,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: _OnboardingPalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _OnboardingPalette.outline),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _OnboardingPalette.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value != null
                        ? DateFormat.yMMMd().format(value!)
                        : 'Choose a date',
                    style: TextStyle(
                      color: value != null
                          ? _OnboardingPalette.textPrimary
                          : _OnboardingPalette.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: _OnboardingPalette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietHelperCard extends StatelessWidget {
  const _QuietHelperCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _OnboardingPalette.tealSoft),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _OnboardingPalette.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameIntroCard extends StatelessWidget {
  const _NameIntroCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final previewName = name.trim().isEmpty ? 'there' : _firstName(name);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF163339), Color(0xFF102023)],
        ),
        border: Border.all(color: _OnboardingPalette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: _OnboardingPalette.tealSoft,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nice to meet you, $previewName.',
            style: const TextStyle(
              color: _OnboardingPalette.textPrimary,
              fontSize: 28,
              height: 1.08,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We’ll use your name where it makes Leko feel warmer and more personal.',
            style: TextStyle(
              color: _OnboardingPalette.textSecondary.withValues(alpha: 0.92),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorWrap<T> extends StatelessWidget {
  const _SelectorWrap({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<_ChipOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _OnboardingPalette.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in options)
              _SelectorChip(
                label: option.label,
                selected: selected == option.value,
                onTap: () => onSelected(option.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChipOption<T> {
  const _ChipOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _SelectorChip extends StatelessWidget {
  const _SelectorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? _OnboardingPalette.surfaceSelected
                : _OnboardingPalette.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? _OnboardingPalette.tealSoft.withValues(alpha: 0.65)
                  : _OnboardingPalette.outline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? _OnboardingPalette.textPrimary
                  : _OnboardingPalette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnchorChoiceTile extends StatelessWidget {
  const _AnchorChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ChoiceCard(
      title: title,
      description: subtitle,
      icon: Icons.anchor_rounded,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _AddedBillRow extends StatelessWidget {
  const _AddedBillRow({required this.bill, required this.onRemove});

  final OnboardingBillDraft bill;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _OnboardingPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _OnboardingPalette.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name,
                  style: const TextStyle(
                    color: _OnboardingPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat.MMMd().format(bill.nextDueDate)} • ${_billFrequencyLabel(bill.frequency)}',
                  style: const TextStyle(
                    color: _OnboardingPalette.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '\$${bill.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: _OnboardingPalette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              color: _OnboardingPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapTile extends StatelessWidget {
  const _RecapTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _OnboardingPalette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _OnboardingPalette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: _OnboardingPalette.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _OnboardingPalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

String _intentTitle(OnboardingIntent intent) => switch (intent) {
      OnboardingIntent.stayOnBudget => 'Stay on budget',
      OnboardingIntent.saveForGoal => 'Save for a goal',
      OnboardingIntent.stopOverspending => 'Stop overspending',
      OnboardingIntent.feelInControl => 'Feel more in control',
      OnboardingIntent.planAroundPayday => 'Plan around payday',
    };

String _intentDescription(OnboardingIntent intent) => switch (intent) {
      OnboardingIntent.stayOnBudget =>
        'Keep spending calmer and more intentional day to day.',
      OnboardingIntent.saveForGoal =>
        'Protect progress toward something meaningful without feeling deprived.',
      OnboardingIntent.stopOverspending =>
        'Catch drift earlier and tighten up before it snowballs.',
      OnboardingIntent.feelInControl =>
        'See your money more clearly and make steadier choices.',
      OnboardingIntent.planAroundPayday =>
        'Let your allowance reset with the rhythm of your income.',
    };

IconData _intentIcon(OnboardingIntent intent) => switch (intent) {
      OnboardingIntent.stayOnBudget => Icons.savings_rounded,
      OnboardingIntent.saveForGoal => Icons.flag_circle_rounded,
      OnboardingIntent.stopOverspending => Icons.insights_rounded,
      OnboardingIntent.feelInControl => Icons.self_improvement_rounded,
      OnboardingIntent.planAroundPayday => Icons.event_repeat_rounded,
    };

String _incomeFrequencyLabel(IncomeFrequency frequency) => switch (frequency) {
      IncomeFrequency.weekly => 'Weekly',
      IncomeFrequency.biweekly => 'Biweekly',
      IncomeFrequency.monthly => 'Monthly',
    };

String _billFrequencyLabel(BillFrequency frequency) => switch (frequency) {
      BillFrequency.weekly => 'Weekly',
      BillFrequency.biweekly => 'Biweekly',
      BillFrequency.monthly => 'Monthly',
      BillFrequency.yearly => 'Yearly',
      BillFrequency.quarterly => 'Quarterly',
    };

String _firstName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).first;
}

abstract final class _OnboardingPalette {
  static const surface = Color(0xFF122124);
  static const surfaceSelected = Color(0xFF173036);
  static const outline = Color(0x2237A29C);
  static const teal = Color(0xFF2E8F88);
  static const tealSoft = Color(0xFF78D0BF);
  static const textPrimary = Color(0xFFF7F3EC);
  static const textSecondary = Color(0xFFA2B3B0);
  static const textMuted = Color(0xFF7B908E);
}
