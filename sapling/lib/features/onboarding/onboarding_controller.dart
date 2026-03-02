import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/db_provider.dart';
import '../../core/providers/recurring_income_providers.dart';
import '../../core/providers/settings_providers.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/sapling_database.dart';
import '../../domain/models/enums.dart';

enum OnboardingStep {
  currency,
  balance,
  income,
  rollover,
  baseline,
  notifications,
  completion,
}

class OnboardingIncomeData {
  final String tempId;
  final String name;
  final IncomeFrequency frequency;
  final DateTime nextPaydayDate;
  final double? expectedAmount;
  final PaydayBehavior paydayBehavior;

  const OnboardingIncomeData({
    required this.tempId,
    required this.name,
    required this.frequency,
    required this.nextPaydayDate,
    this.expectedAmount,
    required this.paydayBehavior,
  });
}

class OnboardingState {
  final OnboardingStep step;
  final Currency currency;
  final double startingBalance;
  final List<OnboardingIncomeData> incomes;
  final RolloverResetType rolloverType;
  final String? paydayAnchorTempId;
  final int baselineDays;
  final PaydayBehavior defaultPaydayBehavior;
  final bool paydayNotifs;
  final bool billNotifs;
  final bool overspendNotifs;
  final bool closeoutNotifs;
  final bool isSubmitting;
  final String? error;

  const OnboardingState({
    this.step = OnboardingStep.currency,
    this.currency = Currency.cad,
    this.startingBalance = 0,
    this.incomes = const [],
    this.rolloverType = RolloverResetType.monthly,
    this.paydayAnchorTempId,
    this.baselineDays = 30,
    this.defaultPaydayBehavior = PaydayBehavior.confirmActualOnPayday,
    this.paydayNotifs = true,
    this.billNotifs = true,
    this.overspendNotifs = true,
    this.closeoutNotifs = true,
    this.isSubmitting = false,
    this.error,
  });

  OnboardingState copyWith({
    OnboardingStep? step,
    Currency? currency,
    double? startingBalance,
    List<OnboardingIncomeData>? incomes,
    RolloverResetType? rolloverType,
    String? Function()? paydayAnchorTempId,
    int? baselineDays,
    PaydayBehavior? defaultPaydayBehavior,
    bool? paydayNotifs,
    bool? billNotifs,
    bool? overspendNotifs,
    bool? closeoutNotifs,
    bool? isSubmitting,
    String? Function()? error,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      currency: currency ?? this.currency,
      startingBalance: startingBalance ?? this.startingBalance,
      incomes: incomes ?? this.incomes,
      rolloverType: rolloverType ?? this.rolloverType,
      paydayAnchorTempId: paydayAnchorTempId != null
          ? paydayAnchorTempId()
          : this.paydayAnchorTempId,
      baselineDays: baselineDays ?? this.baselineDays,
      defaultPaydayBehavior:
          defaultPaydayBehavior ?? this.defaultPaydayBehavior,
      paydayNotifs: paydayNotifs ?? this.paydayNotifs,
      billNotifs: billNotifs ?? this.billNotifs,
      overspendNotifs: overspendNotifs ?? this.overspendNotifs,
      closeoutNotifs: closeoutNotifs ?? this.closeoutNotifs,
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

  void setCurrency(Currency c) => state = state.copyWith(currency: c);
  void setBalance(double b) => state = state.copyWith(startingBalance: b);
  void setRolloverType(RolloverResetType t) =>
      state = state.copyWith(rolloverType: t);
  void setPaydayAnchor(String? id) =>
      state = state.copyWith(paydayAnchorTempId: () => id);
  void setBaselineDays(int d) => state = state.copyWith(baselineDays: d);
  void setDefaultPaydayBehavior(PaydayBehavior b) =>
      state = state.copyWith(defaultPaydayBehavior: b);

  void setNotifs({bool? payday, bool? bill, bool? overspend, bool? closeout}) {
    state = state.copyWith(
      paydayNotifs: payday,
      billNotifs: bill,
      overspendNotifs: overspend,
      closeoutNotifs: closeout,
    );
  }

  void addIncome(OnboardingIncomeData income) {
    state = state.copyWith(incomes: [...state.incomes, income]);
  }

  void removeIncome(String tempId) {
    state = state.copyWith(
      incomes: state.incomes.where((i) => i.tempId != tempId).toList(),
      paydayAnchorTempId: state.paydayAnchorTempId == tempId
          ? () => null
          : null,
    );
  }

  static String newTempId() => _uuid.v4();

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

  String? validate() {
    if (state.rolloverType == RolloverResetType.paydayBased) {
      if (state.incomes.isEmpty) {
        return 'Add at least one recurring income for payday-based rollover.';
      }
      if (state.paydayAnchorTempId == null) {
        return 'Select a Payday Anchor income schedule.';
      }
    }
    return null;
  }

  Future<bool> complete() async {
    final validationError = validate();
    if (validationError != null) {
      state = state.copyWith(error: () => validationError);
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: () => null);

    try {
      final db = _ref.read(databaseProvider);
      final repo = _ref.read(settingsRepositoryProvider);
      final incomeRepo = _ref.read(recurringIncomeRepositoryProvider);
      final now = DateTime.now();

      // Persist recurring incomes and resolve anchor ID
      String? anchorDbId;
      for (final income in state.incomes) {
        final dbId = _uuid.v4();
        if (income.tempId == state.paydayAnchorTempId) anchorDbId = dbId;

        await incomeRepo.insert(RecurringIncomesCompanion.insert(
          id: dbId,
          name: income.name,
          frequency: Value(enumToDb(income.frequency)),
          nextPaydayDate: income.nextPaydayDate,
          expectedAmount: Value(income.expectedAmount),
          paydayBehavior: Value(enumToDb(income.paydayBehavior)),
          isPaydayAnchor:
              Value(income.tempId == state.paydayAnchorTempId),
          createdAt: now,
          updatedAt: now,
        ));
      }

      // Create initial balance adjustment
      if (state.startingBalance != 0) {
        await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            id: _uuid.v4(),
            type: 'adjustment',
            amount: state.startingBalance,
            date: now,
            createdAt: now,
            updatedAt: now,
            note: const Value('Initial balance from onboarding'),
          ),
        );
      }

      // Save settings
      await saveSettingsField(
        repo,
        baseCurrency: state.currency,
        rolloverResetType: state.rolloverType,
        spendingBaselineDays: state.baselineDays,
        defaultPaydayBehavior: state.defaultPaydayBehavior,
        paydayAnchorRecurringIncomeId: () => anchorDbId,
        paydayEnabled: state.paydayNotifs,
        billsEnabled: state.billNotifs,
        overspendEnabled: state.overspendNotifs,
        nightlyCloseoutEnabled: state.closeoutNotifs,
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
