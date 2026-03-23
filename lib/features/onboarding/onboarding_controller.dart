import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/notifications/closeout_notification_service.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/bills_providers.dart';
import '../../core/providers/goals_providers.dart';
import '../../core/providers/ledger_providers.dart';
import '../../core/providers/profile_providers.dart';
import '../../core/providers/recurring_income_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/goals_service.dart';
import '../../domain/services/settings_service.dart';

enum OnboardingStep {
  welcome,
  intent,
  currency,
  balance,
  goal,
  income,
  rollover,
  bills,
  baseline,
  notifications,
  recap,
}

enum OnboardingIntent {
  stayOnBudget,
  saveForGoal,
  stopOverspending,
  feelInControl,
  planAroundPayday,
}

enum NotificationPreference { enable, later }

class OnboardingRecurringIncomeDraft {
  const OnboardingRecurringIncomeDraft({
    required this.id,
    this.name = '',
    this.frequency = IncomeFrequency.biweekly,
    this.nextPaydayDate,
    this.expectedAmount,
    this.paydayBehavior = PaydayBehavior.confirmActualOnPayday,
    this.reminderEnabled = true,
  });

  final String id;
  final String name;
  final IncomeFrequency frequency;
  final DateTime? nextPaydayDate;
  final double? expectedAmount;
  final PaydayBehavior paydayBehavior;
  final bool reminderEnabled;

  OnboardingRecurringIncomeDraft copyWith({
    String? id,
    String? name,
    IncomeFrequency? frequency,
    DateTime? Function()? nextPaydayDate,
    double? Function()? expectedAmount,
    PaydayBehavior? paydayBehavior,
    bool? reminderEnabled,
  }) {
    return OnboardingRecurringIncomeDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      nextPaydayDate:
          nextPaydayDate != null ? nextPaydayDate() : this.nextPaydayDate,
      expectedAmount:
          expectedAmount != null ? expectedAmount() : this.expectedAmount,
      paydayBehavior: paydayBehavior ?? this.paydayBehavior,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}

class OnboardingBillDraft {
  const OnboardingBillDraft({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.nextDueDate,
  });

  final String id;
  final String name;
  final double amount;
  final BillFrequency frequency;
  final DateTime nextDueDate;
}

class OnboardingState {
  const OnboardingState({
    this.step = OnboardingStep.welcome,
    this.name = '',
    this.intent,
    this.baseCurrency,
    this.currentBalance,
    this.goalEnabled = true,
    this.goalName = '',
    this.goalAmount,
    this.goalTargetDate,
    this.goalSavingStyle = SavingStyle.natural,
    this.hasRecurringIncome = false,
    this.recurringIncome,
    this.hasOneTimeIncome = false,
    this.oneTimeIncomeAmount,
    this.oneTimeIncomeDate,
    this.oneTimeIncomeSource = '',
    this.rolloverResetType = RolloverResetType.monthly,
    this.paydayAnchorDraftId,
    this.billDrafts = const [],
    this.spendingBaselineDays = 60,
    this.notificationPreference,
    this.notificationsGranted = false,
    this.isSubmitting = false,
    this.error,
  });

  final OnboardingStep step;
  final String name;
  final OnboardingIntent? intent;
  final Currency? baseCurrency;
  final double? currentBalance;

  final bool goalEnabled;
  final String goalName;
  final double? goalAmount;
  final DateTime? goalTargetDate;
  final SavingStyle goalSavingStyle;

  final bool hasRecurringIncome;
  final OnboardingRecurringIncomeDraft? recurringIncome;
  final bool hasOneTimeIncome;
  final double? oneTimeIncomeAmount;
  final DateTime? oneTimeIncomeDate;
  final String oneTimeIncomeSource;

  final RolloverResetType rolloverResetType;
  final String? paydayAnchorDraftId;

  final List<OnboardingBillDraft> billDrafts;
  final int spendingBaselineDays;

  final NotificationPreference? notificationPreference;
  final bool notificationsGranted;

  final bool isSubmitting;
  final String? error;

  OnboardingState copyWith({
    OnboardingStep? step,
    String? name,
    OnboardingIntent? Function()? intent,
    Currency? Function()? baseCurrency,
    double? Function()? currentBalance,
    bool? goalEnabled,
    String? goalName,
    double? Function()? goalAmount,
    DateTime? Function()? goalTargetDate,
    SavingStyle? goalSavingStyle,
    bool? hasRecurringIncome,
    OnboardingRecurringIncomeDraft? Function()? recurringIncome,
    bool? hasOneTimeIncome,
    double? Function()? oneTimeIncomeAmount,
    DateTime? Function()? oneTimeIncomeDate,
    String? oneTimeIncomeSource,
    RolloverResetType? rolloverResetType,
    String? Function()? paydayAnchorDraftId,
    List<OnboardingBillDraft>? billDrafts,
    int? spendingBaselineDays,
    NotificationPreference? Function()? notificationPreference,
    bool? notificationsGranted,
    bool? isSubmitting,
    String? Function()? error,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      name: name ?? this.name,
      intent: intent != null ? intent() : this.intent,
      baseCurrency: baseCurrency != null ? baseCurrency() : this.baseCurrency,
      currentBalance:
          currentBalance != null ? currentBalance() : this.currentBalance,
      goalEnabled: goalEnabled ?? this.goalEnabled,
      goalName: goalName ?? this.goalName,
      goalAmount: goalAmount != null ? goalAmount() : this.goalAmount,
      goalTargetDate:
          goalTargetDate != null ? goalTargetDate() : this.goalTargetDate,
      goalSavingStyle: goalSavingStyle ?? this.goalSavingStyle,
      hasRecurringIncome: hasRecurringIncome ?? this.hasRecurringIncome,
      recurringIncome:
          recurringIncome != null ? recurringIncome() : this.recurringIncome,
      hasOneTimeIncome: hasOneTimeIncome ?? this.hasOneTimeIncome,
      oneTimeIncomeAmount: oneTimeIncomeAmount != null
          ? oneTimeIncomeAmount()
          : this.oneTimeIncomeAmount,
      oneTimeIncomeDate:
          oneTimeIncomeDate != null ? oneTimeIncomeDate() : this.oneTimeIncomeDate,
      oneTimeIncomeSource: oneTimeIncomeSource ?? this.oneTimeIncomeSource,
      rolloverResetType: rolloverResetType ?? this.rolloverResetType,
      paydayAnchorDraftId: paydayAnchorDraftId != null
          ? paydayAnchorDraftId()
          : this.paydayAnchorDraftId,
      billDrafts: billDrafts ?? this.billDrafts,
      spendingBaselineDays: spendingBaselineDays ?? this.spendingBaselineDays,
      notificationPreference: notificationPreference != null
          ? notificationPreference()
          : this.notificationPreference,
      notificationsGranted: notificationsGranted ?? this.notificationsGranted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error != null ? error() : this.error,
    );
  }

  bool get hasGoalInput =>
      goalName.trim().isNotEmpty ||
      (goalAmount != null && goalAmount! > 0) ||
      goalTargetDate != null;

  bool get needsGoalValidation => goalEnabled && hasGoalInput;
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController(ref);
});

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._ref) : super(const OnboardingState()) {
    final user = _ref.read(currentUserProvider);
    final seededName = _ref.read(profileServiceProvider).displayName(user);
    if (seededName.isNotEmpty) {
      state = state.copyWith(name: seededName);
    }
  }

  final Ref _ref;
  static const _uuid = Uuid();

  static const orderedSteps = OnboardingStep.values;

  void clearError() => state = state.copyWith(error: () => null);

  void goTo(OnboardingStep step) => state = state.copyWith(step: step, error: () => null);

  void setName(String value) =>
      state = state.copyWith(name: value, error: () => null);

  void setIntent(OnboardingIntent intent) =>
      state = state.copyWith(intent: () => intent, error: () => null);

  void setBaseCurrency(Currency currency) =>
      state = state.copyWith(baseCurrency: () => currency, error: () => null);

  void setCurrentBalance(double? amount) =>
      state = state.copyWith(currentBalance: () => amount, error: () => null);

  void setGoalEnabled(bool enabled) {
    state = state.copyWith(
      goalEnabled: enabled,
      error: () => null,
      goalName: enabled ? state.goalName : '',
      goalAmount: () => enabled ? state.goalAmount : null,
      goalTargetDate: () => enabled ? state.goalTargetDate : null,
      goalSavingStyle: enabled ? state.goalSavingStyle : SavingStyle.natural,
    );
  }

  void setGoalName(String value) =>
      state = state.copyWith(goalName: value, error: () => null);

  void setGoalAmount(double? value) =>
      state = state.copyWith(goalAmount: () => value, error: () => null);

  void setGoalTargetDate(DateTime? value) =>
      state = state.copyWith(goalTargetDate: () => value, error: () => null);

  void setGoalSavingStyle(SavingStyle style) =>
      state = state.copyWith(goalSavingStyle: style, error: () => null);

  void setHasRecurringIncome(bool enabled) {
    final draft = enabled
        ? (state.recurringIncome ?? OnboardingRecurringIncomeDraft(id: _uuid.v4()))
        : null;

    state = state.copyWith(
      hasRecurringIncome: enabled,
      recurringIncome: () => draft,
      paydayAnchorDraftId: () {
        if (!enabled && state.rolloverResetType == RolloverResetType.paydayBased) {
          return null;
        }
        if (enabled &&
            state.rolloverResetType == RolloverResetType.paydayBased &&
            state.paydayAnchorDraftId == null) {
          return draft?.id;
        }
        return state.paydayAnchorDraftId;
      },
      error: () => null,
    );
  }

  void updateRecurringIncome({
    String? name,
    IncomeFrequency? frequency,
    DateTime? Function()? nextPaydayDate,
    double? Function()? expectedAmount,
    PaydayBehavior? paydayBehavior,
    bool? reminderEnabled,
  }) {
    final current =
        state.recurringIncome ?? OnboardingRecurringIncomeDraft(id: _uuid.v4());
    final updated = current.copyWith(
      name: name,
      frequency: frequency,
      nextPaydayDate: nextPaydayDate,
      expectedAmount: expectedAmount,
      paydayBehavior: paydayBehavior,
      reminderEnabled: reminderEnabled,
    );

    state = state.copyWith(
      hasRecurringIncome: true,
      recurringIncome: () => updated,
      paydayAnchorDraftId: () {
        if (state.rolloverResetType == RolloverResetType.paydayBased) {
          return state.paydayAnchorDraftId ?? updated.id;
        }
        return state.paydayAnchorDraftId;
      },
      error: () => null,
    );
  }

  void setHasOneTimeIncome(bool enabled) {
    state = state.copyWith(
      hasOneTimeIncome: enabled,
      oneTimeIncomeAmount: () => enabled ? state.oneTimeIncomeAmount : null,
      oneTimeIncomeDate: () => enabled ? state.oneTimeIncomeDate : null,
      oneTimeIncomeSource: enabled ? state.oneTimeIncomeSource : '',
      error: () => null,
    );
  }

  void setOneTimeIncomeAmount(double? amount) => state =
      state.copyWith(oneTimeIncomeAmount: () => amount, error: () => null);

  void setOneTimeIncomeDate(DateTime? date) =>
      state = state.copyWith(oneTimeIncomeDate: () => date, error: () => null);

  void setOneTimeIncomeSource(String source) =>
      state = state.copyWith(oneTimeIncomeSource: source, error: () => null);

  void setRolloverResetType(RolloverResetType type) {
    state = state.copyWith(
      rolloverResetType: type,
      paydayAnchorDraftId: () {
        if (type == RolloverResetType.monthly) return null;
        return state.paydayAnchorDraftId ?? state.recurringIncome?.id;
      },
      error: () => null,
    );
  }

  void setPaydayAnchorDraftId(String? id) =>
      state = state.copyWith(paydayAnchorDraftId: () => id, error: () => null);

  void addBillDraft({
    required String name,
    required double amount,
    required BillFrequency frequency,
    required DateTime nextDueDate,
  }) {
    final draft = OnboardingBillDraft(
      id: _uuid.v4(),
      name: name.trim(),
      amount: amount,
      frequency: frequency,
      nextDueDate: nextDueDate,
    );
    state = state.copyWith(
      billDrafts: [...state.billDrafts, draft],
      error: () => null,
    );
  }

  void removeBillDraft(String id) {
    state = state.copyWith(
      billDrafts: state.billDrafts.where((bill) => bill.id != id).toList(),
      error: () => null,
    );
  }

  void setSpendingBaselineDays(int days) =>
      state = state.copyWith(spendingBaselineDays: days, error: () => null);

  void setNotificationPreference(NotificationPreference preference) =>
      state = state.copyWith(
        notificationPreference: () => preference,
        error: () => null,
      );

  Future<void> requestNotifications() async {
    final granted = await CloseoutNotificationService.instance.requestPermissions();
    state = state.copyWith(
      notificationPreference: () => NotificationPreference.enable,
      notificationsGranted: granted,
      error: () => null,
    );
  }

  Future<bool> next() async {
    final error = validateStep(state.step);
    if (error != null) {
      state = state.copyWith(error: () => error);
      return false;
    }
    final idx = orderedSteps.indexOf(state.step);
    if (idx < orderedSteps.length - 1) {
      state = state.copyWith(
        step: orderedSteps[idx + 1],
        error: () => null,
      );
    }
    return true;
  }

  void back() {
    final idx = orderedSteps.indexOf(state.step);
    if (idx > 0) {
      state = state.copyWith(
        step: orderedSteps[idx - 1],
        error: () => null,
      );
    }
  }

  void skipGoal() {
    state = state.copyWith(
      goalEnabled: false,
      goalName: '',
      goalAmount: () => null,
      goalTargetDate: () => null,
      step: OnboardingStep.income,
      error: () => null,
    );
  }

  void skipBills() {
    state = state.copyWith(step: OnboardingStep.baseline, error: () => null);
  }

  void skipNotifications() {
    state = state.copyWith(
      notificationPreference: () => NotificationPreference.later,
      notificationsGranted: false,
      error: () => null,
    );
  }

  String? validateStep(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
        return state.name.trim().isEmpty
            ? 'Add your name so Leko can feel more personal from the start.'
            : null;
      case OnboardingStep.intent:
        return state.intent == null ? 'Choose what you want help with first.' : null;
      case OnboardingStep.currency:
        return state.baseCurrency == null ? 'Choose a base currency.' : null;
      case OnboardingStep.balance:
        if (state.currentBalance == null) {
          return 'Enter your current chequing balance.';
        }
        if (state.currentBalance! < 0) {
          return 'Current balance cannot be negative.';
        }
        return null;
      case OnboardingStep.goal:
        if (!state.goalEnabled || !state.hasGoalInput) return null;
        return GoalsService.validateName(state.goalName) ??
            GoalsService.validateAmount(state.goalAmount) ??
            GoalsService.validateDate(state.goalTargetDate);
      case OnboardingStep.income:
        return _validateIncomeStep();
      case OnboardingStep.rollover:
        final hasIncomesForAnchor =
            state.hasRecurringIncome && state.recurringIncome != null;
        return SettingsValidation.validateOnboardingComplete(
          hasIncomesForAnchor: hasIncomesForAnchor,
          rolloverType: state.rolloverResetType,
          anchorId: state.paydayAnchorDraftId,
        );
      case OnboardingStep.bills:
        return null;
      case OnboardingStep.baseline:
        return SettingsValidation.validateBaselineDays(state.spendingBaselineDays);
      case OnboardingStep.notifications:
        return state.notificationPreference == null
            ? 'Choose whether to enable notifications now or later.'
            : null;
      case OnboardingStep.recap:
        return _validateFinalState();
    }
  }

  String? _validateIncomeStep() {
    if (!state.hasRecurringIncome && !state.hasOneTimeIncome) {
      return null;
    }

    if (state.hasRecurringIncome) {
      final recurring = state.recurringIncome;
      if (recurring == null) return 'Add your recurring income details.';
      if (recurring.name.trim().isEmpty) {
        return 'Give your recurring income a name.';
      }
      if (recurring.nextPaydayDate == null) {
        return 'Choose the next payday date.';
      }
      final autoPostError = SettingsValidation.validateAutoPost(
        behavior: recurring.paydayBehavior,
        expectedAmount: recurring.expectedAmount,
      );
      if (autoPostError != null) return autoPostError;
    }

    if (state.hasOneTimeIncome) {
      if (state.oneTimeIncomeAmount == null || state.oneTimeIncomeAmount! <= 0) {
        return 'Enter a positive one-time income amount.';
      }
      if (state.oneTimeIncomeDate == null) {
        return 'Choose when the one-time income lands.';
      }
    }
    return null;
  }

  String? _validateFinalState() {
    return validateStep(OnboardingStep.currency) ??
        validateStep(OnboardingStep.welcome) ??
        validateStep(OnboardingStep.balance) ??
        validateStep(OnboardingStep.goal) ??
        validateStep(OnboardingStep.income) ??
        validateStep(OnboardingStep.rollover) ??
        validateStep(OnboardingStep.baseline) ??
        validateStep(OnboardingStep.notifications);
  }

  Future<bool> complete() async {
    final validationError = _validateFinalState();
    if (validationError != null) {
      state = state.copyWith(error: () => validationError);
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: () => null);

    try {
      final settingsRepo = _ref.read(settingsRepositoryProvider);
      final ledgerService = _ref.read(ledgerServiceProvider);
      final goalsService = _ref.read(goalsServiceProvider);
      final billsRepo = _ref.read(billsRepositoryProvider);
      final incomeRepo = _ref.read(recurringIncomeRepositoryProvider);
      final profileService = _ref.read(profileServiceProvider);

      if (_ref.read(currentUserProvider) != null) {
        await profileService.updateDisplayName(state.name);
      }

      String? goalId;
      String? anchorIncomeId;

      final balance = state.currentBalance ?? 0;
      if (balance != 0) {
        await ledgerService.addAdjustment(
          amount: balance,
          date: DateTime.now(),
          note: 'Initial balance from onboarding',
        );
      }

      if (state.goalEnabled && state.hasGoalInput) {
        goalId = await goalsService.create(
          name: state.goalName,
          targetAmount: state.goalAmount!,
          targetDate: state.goalTargetDate!,
          savingStyle: state.goalSavingStyle,
          priorityOrder: 0,
        );
      }

      if (state.hasRecurringIncome && state.recurringIncome != null) {
        final recurring = state.recurringIncome!;
        anchorIncomeId = recurring.id;
        await incomeRepo.insert(
          RecurringIncomesCompanion.insert(
            id: recurring.id,
            name: recurring.name.trim(),
            nextPaydayDate: recurring.nextPaydayDate!,
            frequency: Value(enumToDb(recurring.frequency)),
            expectedAmount: recurring.expectedAmount != null
                ? Value(recurring.expectedAmount)
                : const Value.absent(),
            paydayBehavior: Value(enumToDb(recurring.paydayBehavior)),
            isPaydayAnchor: Value(state.paydayAnchorDraftId == recurring.id),
            reminderEnabled: Value(
              state.notificationPreference == NotificationPreference.enable &&
                  recurring.reminderEnabled,
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      if (state.hasOneTimeIncome && state.oneTimeIncomeAmount != null) {
        await ledgerService.addIncome(
          amount: state.oneTimeIncomeAmount!,
          date: state.oneTimeIncomeDate!,
          postingType: IncomePostingType.manualOneTime,
          source: state.oneTimeIncomeSource.trim().isEmpty
              ? null
              : state.oneTimeIncomeSource.trim(),
          note: 'Added during onboarding',
        );
      }

      for (final bill in state.billDrafts) {
        await billsRepo.insert(
          BillsCompanion.insert(
            id: bill.id,
            name: bill.name,
            amount: bill.amount,
            frequency: Value(enumToDb(bill.frequency)),
            nextDueDate: bill.nextDueDate,
            categoryId: 'cat_other',
            reminderEnabled: Value(
              state.notificationPreference == NotificationPreference.enable,
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      final defaultMode = (goalId != null &&
              (state.intent == OnboardingIntent.saveForGoal ||
                  state.intent == OnboardingIntent.feelInControl))
          ? AllowanceMode.goal
          : AllowanceMode.paycheck;

      await settingsRepo.update(
        AppSettingsCompanion(
          baseCurrency: Value(enumToDb(state.baseCurrency!)),
          rolloverResetType: Value(enumToDb(state.rolloverResetType)),
          spendingBaselineDays: Value(state.spendingBaselineDays),
          allowanceDefaultMode: Value(enumToDb(defaultMode)),
          primaryGoalId: Value(goalId),
          paydayAnchorRecurringIncomeId: Value(
            state.rolloverResetType == RolloverResetType.paydayBased
                ? anchorIncomeId
                : null,
          ),
          defaultPaydayBehavior: Value(
            enumToDb(
              state.recurringIncome?.paydayBehavior ??
                  PaydayBehavior.confirmActualOnPayday,
            ),
          ),
          paydayEnabled: Value(
            state.notificationPreference == NotificationPreference.enable &&
                state.notificationsGranted,
          ),
          billsEnabled: Value(
            state.notificationPreference == NotificationPreference.enable &&
                state.notificationsGranted,
          ),
          overspendEnabled: Value(
            state.notificationPreference == NotificationPreference.enable &&
                state.notificationsGranted,
          ),
          cycleResetEnabled: const Value(false),
          nightlyCloseoutEnabled: Value(
            state.notificationPreference == NotificationPreference.enable &&
                state.notificationsGranted,
          ),
          nightlyCloseoutTime: const Value('21:00'),
          onboardingCompleted: const Value(true),
        ),
      );

      state = state.copyWith(isSubmitting: false, error: () => null);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: () => 'Failed to finish onboarding: $e',
      );
      return false;
    }
  }
}
