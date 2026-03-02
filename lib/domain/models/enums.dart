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
  double get multiplier => switch (this) {
        SavingStyle.easy => 1.00,
        SavingStyle.natural => 0.90,
        SavingStyle.aggressive => 0.75,
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
