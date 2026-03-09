import '../db/sapling_database.dart';
import 'supabase_json.dart';

/// Maps Supabase (snake_case) rows to/from Drift entity types.
/// Used by Supabase repositories.

AppSetting appSettingFromSupabase(Map<String, dynamic> row) =>
    AppSetting.fromJson(camelCaseKeys(row));

Map<String, dynamic> appSettingToSupabase(AppSetting e) =>
    prepareForSupabase(e.toJson());

Category categoryFromSupabase(Map<String, dynamic> row) =>
    Category.fromJson(camelCaseKeys(row));

Map<String, dynamic> categoryToSupabase(Category e) =>
    prepareForSupabase(e.toJson());

Transaction transactionFromSupabase(Map<String, dynamic> row) =>
    Transaction.fromJson(camelCaseKeys(row));

Map<String, dynamic> transactionToSupabase(Transaction e) =>
    prepareForSupabase(e.toJson());

Goal goalFromSupabase(Map<String, dynamic> row) =>
    Goal.fromJson(camelCaseKeys(row));

Map<String, dynamic> goalToSupabase(Goal e) =>
    prepareForSupabase(e.toJson());

RecurringIncome recurringIncomeFromSupabase(Map<String, dynamic> row) =>
    RecurringIncome.fromJson(camelCaseKeys(row));

Map<String, dynamic> recurringIncomeToSupabase(RecurringIncome e) =>
    prepareForSupabase(e.toJson());

Bill billFromSupabase(Map<String, dynamic> row) =>
    Bill.fromJson(camelCaseKeys(row));

Map<String, dynamic> billToSupabase(Bill e) =>
    prepareForSupabase(e.toJson());

Person personFromSupabase(Map<String, dynamic> row) =>
    Person.fromJson(camelCaseKeys(row));

Map<String, dynamic> personToSupabase(Person e) =>
    prepareForSupabase(e.toJson());

SplitEntry splitEntryFromSupabase(Map<String, dynamic> row) =>
    SplitEntry.fromJson(camelCaseKeys(row));

Map<String, dynamic> splitEntryToSupabase(SplitEntry e) =>
    prepareForSupabase(e.toJson());

SplitShare splitShareFromSupabase(Map<String, dynamic> row) =>
    SplitShare.fromJson(camelCaseKeys(row));

Map<String, dynamic> splitShareToSupabase(SplitShare e) =>
    prepareForSupabase(e.toJson());

DailyCloseout dailyCloseoutFromSupabase(Map<String, dynamic> row) =>
    DailyCloseout.fromJson(camelCaseKeys(row));

Map<String, dynamic> dailyCloseoutToSupabase(DailyCloseout e) =>
    prepareForSupabase(e.toJson());

RecoveryPlan recoveryPlanFromSupabase(Map<String, dynamic> row) =>
    RecoveryPlan.fromJson(camelCaseKeys(row));

Map<String, dynamic> recoveryPlanToSupabase(RecoveryPlan e) =>
    prepareForSupabase(e.toJson());
