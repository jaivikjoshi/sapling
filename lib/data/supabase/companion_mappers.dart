import 'package:drift/drift.dart';

import '../db/leko_database.dart';

/// Converts Drift Companions to Supabase (snake_case) maps for insert/update.
/// Used by Supabase repositories that keep the Companion API.

Map<String, dynamic> billsCompanionToSupabase(BillsCompanion c, String userId) {
  final m = <String, dynamic>{'user_id': userId};
  if (c.id.present) m['id'] = c.id.value;
  if (c.name.present) m['name'] = c.name.value;
  if (c.amount.present) m['amount'] = c.amount.value;
  if (c.frequency.present) m['frequency'] = c.frequency.value;
  else m['frequency'] = 'monthly';
  if (c.nextDueDate.present) m['next_due_date'] = c.nextDueDate.value.toIso8601String();
  if (c.categoryId.present) m['category_id'] = c.categoryId.value;
  if (c.defaultLabel.present) m['default_label'] = c.defaultLabel.value;
  else m['default_label'] = 'green';
  if (c.autopay.present) m['autopay'] = c.autopay.value;
  else m['autopay'] = false;
  if (c.reminderEnabled.present) m['reminder_enabled'] = c.reminderEnabled.value;
  else m['reminder_enabled'] = true;
  if (c.reminderLeadTimeDays.present) m['reminder_lead_time_days'] = c.reminderLeadTimeDays.value;
  else m['reminder_lead_time_days'] = 3;
  if (c.createdAt.present) m['created_at'] = c.createdAt.value.toIso8601String();
  if (c.updatedAt.present) m['updated_at'] = c.updatedAt.value.toIso8601String();
  return m;
}

Map<String, dynamic> goalsCompanionToSupabase(GoalsCompanion c, String userId) {
  final m = <String, dynamic>{'user_id': userId};
  if (c.id.present) m['id'] = c.id.value;
  if (c.name.present) m['name'] = c.name.value;
  if (c.targetAmount.present) m['target_amount'] = c.targetAmount.value;
  if (c.targetDate.present) m['target_date'] = c.targetDate.value.toIso8601String();
  if (c.savingStyle.present) m['saving_style'] = c.savingStyle.value;
  else m['saving_style'] = 'natural';
  if (c.priorityOrder.present) m['priority_order'] = c.priorityOrder.value;
  else m['priority_order'] = 0;
  if (c.isArchived.present) m['is_archived'] = c.isArchived.value;
  else m['is_archived'] = false;
  if (c.createdAt.present) m['created_at'] = c.createdAt.value.toIso8601String();
  if (c.updatedAt.present) m['updated_at'] = c.updatedAt.value.toIso8601String();
  return m;
}

Map<String, dynamic> recurringIncomesCompanionToSupabase(RecurringIncomesCompanion c, String userId) {
  final m = <String, dynamic>{'user_id': userId};
  if (c.id.present) m['id'] = c.id.value;
  if (c.name.present) m['name'] = c.name.value;
  if (c.frequency.present) m['frequency'] = c.frequency.value;
  else m['frequency'] = 'monthly';
  if (c.nextPaydayDate.present) m['next_payday_date'] = c.nextPaydayDate.value.toIso8601String();
  if (c.expectedAmount.present) m['expected_amount'] = c.expectedAmount.value;
  if (c.paydayBehavior.present) m['payday_behavior'] = c.paydayBehavior.value;
  else m['payday_behavior'] = 'confirm_actual_on_payday';
  if (c.isPaydayAnchorEligible.present) m['is_payday_anchor_eligible'] = c.isPaydayAnchorEligible.value;
  else m['is_payday_anchor_eligible'] = true;
  if (c.isPaydayAnchor.present) m['is_payday_anchor'] = c.isPaydayAnchor.value;
  else m['is_payday_anchor'] = false;
  if (c.reminderEnabled.present) m['reminder_enabled'] = c.reminderEnabled.value;
  else m['reminder_enabled'] = false;
  if (c.reminderTime.present) m['reminder_time'] = c.reminderTime.value;
  if (c.createdAt.present) m['created_at'] = c.createdAt.value.toIso8601String();
  if (c.updatedAt.present) m['updated_at'] = c.updatedAt.value.toIso8601String();
  return m;
}

Map<String, dynamic> personsCompanionToSupabase(PersonsCompanion c, String userId) {
  final m = <String, dynamic>{'user_id': userId};
  if (c.id.present) m['id'] = c.id.value;
  if (c.name.present) m['name'] = c.name.value;
  if (c.handle.present) m['handle'] = c.handle.value;
  if (c.createdAt.present) m['created_at'] = c.createdAt.value.toIso8601String();
  if (c.updatedAt.present) m['updated_at'] = c.updatedAt.value.toIso8601String();
  return m;
}

Map<String, dynamic> splitEntriesCompanionToSupabase(SplitEntriesCompanion c, String userId) {
  final m = <String, dynamic>{'user_id': userId};
  if (c.id.present) m['id'] = c.id.value;
  if (c.date.present) m['date'] = c.date.value.toIso8601String();
  if (c.description.present) m['description'] = c.description.value;
  if (c.totalAmount.present) m['total_amount'] = c.totalAmount.value;
  if (c.paidBy.present) m['paid_by'] = c.paidBy.value;
  if (c.linkToExpenseTransactionId.present) m['link_to_expense_transaction_id'] = c.linkToExpenseTransactionId.value;
  if (c.status.present) m['status'] = c.status.value;
  else m['status'] = 'open';
  if (c.createdAt.present) m['created_at'] = c.createdAt.value.toIso8601String();
  if (c.updatedAt.present) m['updated_at'] = c.updatedAt.value.toIso8601String();
  return m;
}

Map<String, dynamic> splitSharesCompanionToSupabase(SplitSharesCompanion c) {
  final m = <String, dynamic>{};
  if (c.id.present) m['id'] = c.id.value;
  if (c.splitEntryId.present) m['split_entry_id'] = c.splitEntryId.value;
  if (c.personId.present) m['person_id'] = c.personId.value;
  if (c.shareAmount.present) m['share_amount'] = c.shareAmount.value;
  return m;
}

Map<String, dynamic> dailyCloseoutsCompanionToSupabase(DailyCloseoutsCompanion c, String userId) {
  final m = <String, dynamic>{'user_id': userId};
  if (c.id.present) m['id'] = c.id.value;
  if (c.date.present) {
    final d = c.date.value;
    m['date'] = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
  if (c.result.present) m['result'] = c.result.value;
  if (c.createdAt.present) m['created_at'] = c.createdAt.value.toIso8601String();
  return m;
}

Map<String, dynamic> recoveryPlansCompanionToSupabase(RecoveryPlansCompanion c, String userId) {
  final m = <String, dynamic>{'user_id': userId};
  if (c.id.present) m['id'] = c.id.value;
  if (c.createdAt.present) m['created_at'] = c.createdAt.value.toIso8601String();
  if (c.triggerTransactionId.present) m['trigger_transaction_id'] = c.triggerTransactionId.value;
  if (c.overspendAmount.present) m['overspend_amount'] = c.overspendAmount.value;
  if (c.planType.present) m['plan_type'] = c.planType.value;
  if (c.parameters.present) m['parameters'] = c.parameters.value;
  else m['parameters'] = '{}';
  if (c.status.present) m['status'] = c.status.value;
  else m['status'] = 'active';
  return m;
}
