import '../models/enums.dart';
import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';

class UserSettings {
  final Currency baseCurrency;
  final RolloverResetType rolloverResetType;
  final int spendingBaselineDays;
  final AllowanceMode allowanceDefaultMode;
  final String? primaryGoalId;
  final String? paydayAnchorRecurringIncomeId;
  final PaydayBehavior defaultPaydayBehavior;
  final bool paydayEnabled;
  final bool billsEnabled;
  final bool overspendEnabled;
  final bool cycleResetEnabled;
  final bool nightlyCloseoutEnabled;
  final String nightlyCloseoutTime;
  final bool onboardingCompleted;

  const UserSettings({
    required this.baseCurrency,
    required this.rolloverResetType,
    required this.spendingBaselineDays,
    required this.allowanceDefaultMode,
    this.primaryGoalId,
    this.paydayAnchorRecurringIncomeId,
    required this.defaultPaydayBehavior,
    required this.paydayEnabled,
    required this.billsEnabled,
    required this.overspendEnabled,
    required this.cycleResetEnabled,
    required this.nightlyCloseoutEnabled,
    required this.nightlyCloseoutTime,
    required this.onboardingCompleted,
  });

  factory UserSettings.fromDb(AppSetting row) {
    return UserSettings(
      baseCurrency: enumFromDb(row.baseCurrency, Currency.values),
      rolloverResetType:
          enumFromDb(row.rolloverResetType, RolloverResetType.values),
      spendingBaselineDays: row.spendingBaselineDays,
      allowanceDefaultMode:
          enumFromDb(row.allowanceDefaultMode, AllowanceMode.values),
      primaryGoalId: row.primaryGoalId,
      paydayAnchorRecurringIncomeId: row.paydayAnchorRecurringIncomeId,
      defaultPaydayBehavior:
          enumFromDb(row.defaultPaydayBehavior, PaydayBehavior.values),
      paydayEnabled: row.paydayEnabled,
      billsEnabled: row.billsEnabled,
      overspendEnabled: row.overspendEnabled,
      cycleResetEnabled: row.cycleResetEnabled,
      nightlyCloseoutEnabled: row.nightlyCloseoutEnabled,
      nightlyCloseoutTime: row.nightlyCloseoutTime,
      onboardingCompleted: row.onboardingCompleted,
    );
  }

  static const defaults = UserSettings(
    baseCurrency: Currency.cad,
    rolloverResetType: RolloverResetType.monthly,
    spendingBaselineDays: 30,
    allowanceDefaultMode: AllowanceMode.paycheck,
    defaultPaydayBehavior: PaydayBehavior.confirmActualOnPayday,
    paydayEnabled: true,
    billsEnabled: true,
    overspendEnabled: true,
    cycleResetEnabled: false,
    nightlyCloseoutEnabled: true,
    nightlyCloseoutTime: '21:00',
    onboardingCompleted: false,
  );

  UserSettings copyWith({
    Currency? baseCurrency,
    RolloverResetType? rolloverResetType,
    int? spendingBaselineDays,
    AllowanceMode? allowanceDefaultMode,
    String? Function()? primaryGoalId,
    String? Function()? paydayAnchorRecurringIncomeId,
    PaydayBehavior? defaultPaydayBehavior,
    bool? paydayEnabled,
    bool? billsEnabled,
    bool? overspendEnabled,
    bool? cycleResetEnabled,
    bool? nightlyCloseoutEnabled,
    String? nightlyCloseoutTime,
    bool? onboardingCompleted,
  }) {
    return UserSettings(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      rolloverResetType: rolloverResetType ?? this.rolloverResetType,
      spendingBaselineDays: spendingBaselineDays ?? this.spendingBaselineDays,
      allowanceDefaultMode: allowanceDefaultMode ?? this.allowanceDefaultMode,
      primaryGoalId:
          primaryGoalId != null ? primaryGoalId() : this.primaryGoalId,
      paydayAnchorRecurringIncomeId: paydayAnchorRecurringIncomeId != null
          ? paydayAnchorRecurringIncomeId()
          : this.paydayAnchorRecurringIncomeId,
      defaultPaydayBehavior:
          defaultPaydayBehavior ?? this.defaultPaydayBehavior,
      paydayEnabled: paydayEnabled ?? this.paydayEnabled,
      billsEnabled: billsEnabled ?? this.billsEnabled,
      overspendEnabled: overspendEnabled ?? this.overspendEnabled,
      cycleResetEnabled: cycleResetEnabled ?? this.cycleResetEnabled,
      nightlyCloseoutEnabled:
          nightlyCloseoutEnabled ?? this.nightlyCloseoutEnabled,
      nightlyCloseoutTime: nightlyCloseoutTime ?? this.nightlyCloseoutTime,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
