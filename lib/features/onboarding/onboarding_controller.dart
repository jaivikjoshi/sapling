import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/ledger_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/providers/bills_providers.dart';
import '../../core/providers/goals_providers.dart';
import '../../core/providers/recurring_income_providers.dart';
import '../../data/db/leko_database.dart';
import '../../domain/models/enums.dart';

enum OnboardingStep {
  welcome,
  primaryNeed,
  moneySituation,
  rhythm,
  protectGoal,
  balance,
  bills,
  safeToSpend,
  focusGoal,
  supportStyle,
  permissions,
  activation,
}

enum IncomeRhythm {
  weekly,
  biweekly,
  twiceAMonth,
  monthly,
  irregular,
}

enum SupportStyle {
  gentleReminders,
  dailyLimits,
  goalMotivation,
  billAlerts,
  weeklyCheckins,
}

class OnboardingState {
  final OnboardingStep step;
  final String? primaryNeed;
  final String? moneySituation;
  final IncomeRhythm? rhythm;
  final double incomeAmount;
  final String? protectGoal;
  final double startingBalance;
  final List<String> selectedBills;
  final String? focusGoal;
  final double goalAmount;
  final DateTime? goalTargetDate;
  final SupportStyle? supportStyle;

  // Internal flags
  final bool hasRequestedNotifications;
  final bool isSubmitting;
  final String? error;

  const OnboardingState({
    this.step = OnboardingStep.welcome,
    this.primaryNeed,
    this.moneySituation,
    this.rhythm,
    this.incomeAmount = 0,
    this.protectGoal,
    this.startingBalance = 0,
    this.selectedBills = const [],
    this.focusGoal,
    this.goalAmount = 0,
    this.goalTargetDate,
    this.supportStyle,
    this.hasRequestedNotifications = false,
    this.isSubmitting = false,
    this.error,
  });

  OnboardingState copyWith({
    OnboardingStep? step,
    String? primaryNeed,
    String? moneySituation,
    IncomeRhythm? rhythm,
    double? incomeAmount,
    String? protectGoal,
    double? startingBalance,
    List<String>? selectedBills,
    String? focusGoal,
    double? goalAmount,
    DateTime? Function()? goalTargetDate,
    SupportStyle? supportStyle,
    bool? hasRequestedNotifications,
    bool? isSubmitting,
    String? Function()? error,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      primaryNeed: primaryNeed ?? this.primaryNeed,
      moneySituation: moneySituation ?? this.moneySituation,
      rhythm: rhythm ?? this.rhythm,
      incomeAmount: incomeAmount ?? this.incomeAmount,
      protectGoal: protectGoal ?? this.protectGoal,
      startingBalance: startingBalance ?? this.startingBalance,
      selectedBills: selectedBills ?? this.selectedBills,
      focusGoal: focusGoal ?? this.focusGoal,
      goalAmount: goalAmount ?? this.goalAmount,
      goalTargetDate: goalTargetDate != null ? goalTargetDate() : this.goalTargetDate,
      supportStyle: supportStyle ?? this.supportStyle,
      hasRequestedNotifications: hasRequestedNotifications ?? this.hasRequestedNotifications,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error != null ? error() : this.error,
    );
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController(ref);
});

class OnboardingController extends StateNotifier<OnboardingState> {
  final Ref _ref;
  static const _uuid = Uuid();

  OnboardingController(this._ref) : super(const OnboardingState());

  void setPrimaryNeed(String need) => state = state.copyWith(primaryNeed: need);
  void setMoneySituation(String situation) => state = state.copyWith(moneySituation: situation);
  void setRhythm(IncomeRhythm rhythm) => state = state.copyWith(rhythm: rhythm);
  void setIncomeAmount(double amount) => state = state.copyWith(incomeAmount: amount);
  void setProtectGoal(String goal) => state = state.copyWith(protectGoal: goal);
  void setBalance(double b) => state = state.copyWith(startingBalance: b);
  void toggleBill(String bill) {
    if (state.selectedBills.contains(bill)) {
      state = state.copyWith(selectedBills: state.selectedBills.where((b) => b != bill).toList());
    } else {
      state = state.copyWith(selectedBills: [...state.selectedBills, bill]);
    }
  }
  void setFocusGoal(String goal) => state = state.copyWith(focusGoal: goal);
  void setGoalAmount(double amount) => state = state.copyWith(goalAmount: amount);
  void setGoalTargetDate(DateTime date) => state = state.copyWith(goalTargetDate: () => date);
  void setSupportStyle(SupportStyle style) => state = state.copyWith(supportStyle: style);
  void setHasRequestedNotifications() => state = state.copyWith(hasRequestedNotifications: true);

  void goTo(OnboardingStep step) => state = state.copyWith(step: step);

  void next() {
    final steps = OnboardingStep.values;
    final idx = steps.indexOf(state.step);
    if (idx < steps.length - 1) {
      state = state.copyWith(step: steps[idx + 1], error: () => null);
    }
  }

  void back() {
    final steps = OnboardingStep.values;
    final idx = steps.indexOf(state.step);
    if (idx > 0) {
      state = state.copyWith(step: steps[idx - 1], error: () => null);
    }
  }

  Future<bool> complete() async {
    state = state.copyWith(isSubmitting: true, error: () => null);

    try {
      final repo = _ref.read(settingsRepositoryProvider);
      final txnRepo = _ref.read(transactionsRepositoryProvider);
      final billsRepo = _ref.read(billsRepositoryProvider);
      final goalsRepo = _ref.read(goalsRepositoryProvider);
      final incomeRepo = _ref.read(recurringIncomeRepositoryProvider);
      final now = DateTime.now();

      // Create initial balance adjustment
      if (state.startingBalance != 0) {
        await txnRepo.insert(Transaction(
          id: _uuid.v4(),
          type: 'adjustment',
          amount: state.startingBalance,
          date: now,
          note: 'Initial balance from onboarding',
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Add selected bills (using defaults for amounts/dates since it's just a sketch)
      for (final billName in state.selectedBills) {
        await billsRepo.insert(BillsCompanion.insert(
          id: _uuid.v4(),
          name: billName,
          amount: 100.0, // Placeholder amount
          categoryId: 'cat_other', // Default category
          nextDueDate: DateTime(now.year, now.month, 1),
          autopay: const Value(true),
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Add focus goal
      if (state.focusGoal != null && state.goalAmount > 0) {
        await goalsRepo.insert(GoalsCompanion.insert(
          id: _uuid.v4(),
          name: state.focusGoal!,
          targetAmount: state.goalAmount,
          targetDate: state.goalTargetDate ?? DateTime(now.year + 1, now.month, now.day),
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Add recurring income if specified
      String? anchorIncomeId;
      if (state.rhythm != null && state.incomeAmount > 0) {
        anchorIncomeId = _uuid.v4();
        // Just a sketch: next payday 1 week from now, standardizing interval roughly
        final nextPayday = now.add(const Duration(days: 7));
        String frequency = 'monthly';
        switch (state.rhythm!) {
          case IncomeRhythm.weekly:
            frequency = 'weekly';
            break;
          case IncomeRhythm.biweekly:
            frequency = 'biweekly';
            break;
          case IncomeRhythm.twiceAMonth:
            frequency = 'twice_a_month'; // Approximate
            break;
          case IncomeRhythm.monthly:
            frequency = 'monthly';
            break;
          case IncomeRhythm.irregular:
            frequency = 'irregular'; // Fallback
            break;
        }

        await incomeRepo.insert(RecurringIncomesCompanion.insert(
          id: anchorIncomeId,
          name: 'Primary Income',
          expectedAmount: Value(state.incomeAmount),
          nextPaydayDate: nextPayday,
          frequency: Value(frequency),
          isPaydayAnchor: const Value(true),
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Configure notification settings based on support style
      bool paydayNotifs = true;
      bool billNotifs = true;
      bool overspendNotifs = true;
      bool closeoutNotifs = true;

      switch (state.supportStyle) {
        case SupportStyle.gentleReminders:
          // Minimal: just bill reminders and payday
          overspendNotifs = false;
          closeoutNotifs = false;
          break;
        case SupportStyle.dailyLimits:
          // All alerts on — overspend + closeout are key
          break;
        case SupportStyle.goalMotivation:
          // Focus on goals, less on daily spend
          overspendNotifs = false;
          break;
        case SupportStyle.billAlerts:
          // Focus on bills, less on everything else
          overspendNotifs = false;
          closeoutNotifs = false;
          break;
        case SupportStyle.weeklyCheckins:
          // Weekly digest style — disable real-time alerts
          overspendNotifs = false;
          closeoutNotifs = true;
          break;
        case null:
          // Default: balanced
          break;
      }

      // Save settings
      await saveSettingsField(
        repo,
        baseCurrency: Currency.cad, // Defaulting to CAD to simplify onboarding, user can change in settings
        rolloverResetType: RolloverResetType.monthly, // Default
        spendingBaselineDays: 30, // Default
        defaultPaydayBehavior: PaydayBehavior.confirmActualOnPayday, // Default
        paydayAnchorRecurringIncomeId: () => anchorIncomeId,
        paydayEnabled: paydayNotifs,
        billsEnabled: billNotifs,
        overspendEnabled: overspendNotifs,
        nightlyCloseoutEnabled: closeoutNotifs,
      );

      await repo.markOnboardingComplete();

      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: () => 'Failed to save: $e',
      );
      return false;
    }
  }
}
