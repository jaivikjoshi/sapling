import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/ledger_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/providers/bills_providers.dart';
import '../../core/providers/goals_providers.dart';
import '../../data/db/leko_database.dart';
import '../../domain/models/enums.dart';

enum OnboardingStep {
  welcome,
  primaryNeed,
  rhythm,
  promise,
  balance,
  bills,
  focusGoal,
  supportStyle,
  permissions,
  monetization,
  activation,
}

enum IncomeRhythm {
  predictable,
  irregular,
}

enum SupportStyle {
  gentle,
  steady,
  focused,
}

class OnboardingState {
  final OnboardingStep step;
  final String? primaryNeed;
  final IncomeRhythm? rhythm;
  final double startingBalance;
  final List<String> selectedBills;
  final String? focusGoal;
  final SupportStyle? supportStyle;
  final bool optedIntoTrial;
  
  // Internal flags
  final bool hasRequestedNotifications;
  final bool isSubmitting;
  final String? error;

  const OnboardingState({
    this.step = OnboardingStep.welcome,
    this.primaryNeed,
    this.rhythm,
    this.startingBalance = 0,
    this.selectedBills = const [],
    this.focusGoal,
    this.supportStyle,
    this.optedIntoTrial = false,
    this.hasRequestedNotifications = false,
    this.isSubmitting = false,
    this.error,
  });

  OnboardingState copyWith({
    OnboardingStep? step,
    String? primaryNeed,
    IncomeRhythm? rhythm,
    double? startingBalance,
    List<String>? selectedBills,
    String? focusGoal,
    SupportStyle? supportStyle,
    bool? optedIntoTrial,
    bool? hasRequestedNotifications,
    bool? isSubmitting,
    String? Function()? error,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      primaryNeed: primaryNeed ?? this.primaryNeed,
      rhythm: rhythm ?? this.rhythm,
      startingBalance: startingBalance ?? this.startingBalance,
      selectedBills: selectedBills ?? this.selectedBills,
      focusGoal: focusGoal ?? this.focusGoal,
      supportStyle: supportStyle ?? this.supportStyle,
      optedIntoTrial: optedIntoTrial ?? this.optedIntoTrial,
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
  void setRhythm(IncomeRhythm rhythm) => state = state.copyWith(rhythm: rhythm);
  void setBalance(double b) => state = state.copyWith(startingBalance: b);
  void toggleBill(String bill) {
    if (state.selectedBills.contains(bill)) {
      state = state.copyWith(selectedBills: state.selectedBills.where((b) => b != bill).toList());
    } else {
      state = state.copyWith(selectedBills: [...state.selectedBills, bill]);
    }
  }
  void setFocusGoal(String goal) => state = state.copyWith(focusGoal: goal);
  void setSupportStyle(SupportStyle style) => state = state.copyWith(supportStyle: style);
  void setOptedIntoTrial(bool optedIn) => state = state.copyWith(optedIntoTrial: optedIn);
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
      if (state.focusGoal != null) {
        await goalsRepo.insert(GoalsCompanion.insert(
          id: _uuid.v4(),
          name: state.focusGoal!,
          targetAmount: 1000.0, // Default target
          targetDate: DateTime(now.year + 1, now.month, now.day),
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Configure notification settings based on support style
      bool paydayNotifs = true;
      bool billNotifs = true;
      bool overspendNotifs = true;
      bool closeoutNotifs = true;

      if (state.supportStyle == SupportStyle.gentle) {
        overspendNotifs = false;
        closeoutNotifs = false;
      } else if (state.supportStyle == SupportStyle.steady) {
        overspendNotifs = false;
        closeoutNotifs = true;
      }

      // Save settings
      await saveSettingsField(
        repo,
        baseCurrency: Currency.cad, // Defaulting to CAD to simplify onboarding, user can change in settings
        rolloverResetType: RolloverResetType.monthly, // Default
        spendingBaselineDays: 30, // Default
        defaultPaydayBehavior: PaydayBehavior.confirmActualOnPayday, // Default
        paydayAnchorRecurringIncomeId: () => null,
        paydayEnabled: paydayNotifs,
        billsEnabled: billNotifs,
        overspendEnabled: overspendNotifs,
        nightlyCloseoutEnabled: closeoutNotifs,
      );

      // Technically here in a real app we'd save the Trial Opt In via RevenueCat/Server check
      // For now, we just mark onboarding complete
      
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
