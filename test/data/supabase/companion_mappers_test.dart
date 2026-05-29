import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leko/data/db/leko_database.dart';
import 'package:leko/data/supabase/companion_mappers.dart';

void main() {
  group('billsCompanionToSupabase', () {
    test('partial update only includes present fields', () {
      final map = billsCompanionToSupabase(
        BillsCompanion(
          nextDueDate: const Value(DateTime(2025, 6, 1)),
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

    test('insert companion includes explicit fields only', () {
      final map = billsCompanionToSupabase(
        BillsCompanion.insert(
          id: 'bill-1',
          name: 'Rent',
          amount: 1200,
          frequency: const Value('monthly'),
          nextDueDate: DateTime(2025, 5, 1),
          categoryId: 'cat-1',
          defaultLabel: const Value('green'),
          autopay: const Value(true),
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
        'user-1',
      );

      expect(map['autopay'], true);
      expect(map['frequency'], 'monthly');
      expect(map['name'], 'Rent');
    });
  });

  group('recurringIncomesCompanionToSupabase', () {
    test('partial update does not reset payday_behavior', () {
      final map = recurringIncomesCompanionToSupabase(
        RecurringIncomesCompanion(
          nextPaydayDate: const Value(DateTime(2025, 6, 15)),
          updatedAt: Value(DateTime(2025, 5, 1)),
        ),
        'user-1',
      );

      expect(map.keys, containsAll(['user_id', 'next_payday_date', 'updated_at']));
      expect(map, isNot(contains('payday_behavior')));
      expect(map, isNot(contains('is_payday_anchor')));
    });
  });
}
