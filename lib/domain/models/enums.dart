enum Currency { cad, usd }

enum RolloverResetType { monthly, paydayBased }

enum AllowanceMode { paycheck, goal }

enum TransactionType { expense, income, adjustment }

enum SpendLabel { green, orange, red }

enum IncomePostingType { confirmedActual, autoPostedExpected, manualOneTime }

enum PaydayBehavior { confirmActualOnPayday, autoPostExpected }

enum IncomeFrequency { weekly, biweekly, monthly }

enum BillFrequency { weekly, biweekly, monthly, quarterly, yearly }

enum SavingStyle { easy, natural, aggressive }

extension SavingStyleMultiplier on SavingStyle {
  /// Multiplier applied to baseline variable spend.
  /// Higher = more lenient daily spending ceiling.
  double get multiplier => switch (this) {
        SavingStyle.easy => 1.10,       // Let the user breathe a little more
        SavingStyle.natural => 1.00,    // Baseline as-is
        SavingStyle.aggressive => 0.85, // Tighten variable spend to protect savings
      };
}

enum CloseoutResult { noSpend, addedExpense, notSure, skipped }

enum RecoveryPlanType {
  reduceNextNDays,
  reduceWeekendsOnly,
  pushGoalDate,
  tempSwitchSavingStyle,
}

enum RecoveryPlanStatus { active, completed, canceled }

enum SplitStatus { open, settled }
