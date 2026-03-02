import 'package:drift/drift.dart';

class AppSettings extends Table {
  TextColumn get id => text().withDefault(const Constant('singleton'))();
  TextColumn get baseCurrency => text().withDefault(const Constant('cad'))();
  TextColumn get rolloverResetType =>
      text().withDefault(const Constant('monthly'))();
  IntColumn get spendingBaselineDays =>
      integer().withDefault(const Constant(30))();
  TextColumn get allowanceDefaultMode =>
      text().withDefault(const Constant('paycheck'))();
  TextColumn get primaryGoalId => text().nullable()();
  TextColumn get paydayAnchorRecurringIncomeId => text().nullable()();
  TextColumn get defaultPaydayBehavior =>
      text().withDefault(const Constant('confirm_actual_on_payday'))();
  BoolColumn get paydayEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get billsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get overspendEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get cycleResetEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get nightlyCloseoutEnabled =>
      boolean().withDefault(const Constant(true))();
  TextColumn get nightlyCloseoutTime =>
      text().withDefault(const Constant('21:00'))();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
