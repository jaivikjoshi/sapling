import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leko/data/db/leko_database.dart';
import 'package:leko/data/supabase/companion_mappers.dart';

void main() {
  group('billsCompanionToSupabase', () {
    test('partial update only includes present fields', () {
      final map = billsCompanionToSupabase(
        BillsCompanion(
          nextDueDate: Value(DateTime(2025, 6, 1)),
          updatedAt: Value(DateTime(2025, 5, 1)),
        ),
        'user-1',
      );

      expect(map.keys, containsAll(['user_id', 'next_due_date', 'updated_at']));
      expect(map, isNot(contains('autopay')));
      expect(map, isNot(contains('frequency')));
      expect(map, isNot(contains('default_label')));
      expect(map, isNot(contains('reminder_enabled')));
    });
  });

  group('recurringIncomesCompanionToSupabase', () {
    test('partial update does not reset payday behavior flags', () {
      final map = recurringIncomesCompanionToSupabase(
        RecurringIncomesCompanion(
          nextPaydayDate: Value(DateTime(2025, 6, 15)),
          updatedAt: Value(DateTime(2025, 5, 1)),
        ),
        'user-1',
      );

      expect(
        map.keys,
        containsAll(['user_id', 'next_payday_date', 'updated_at']),
      );
      expect(map, isNot(contains('payday_behavior')));
      expect(map, isNot(contains('is_payday_anchor')));
      expect(map, isNot(contains('reminder_enabled')));
    });
  });
}
