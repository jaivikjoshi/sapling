import 'package:flutter_test/flutter_test.dart';

import 'package:leko/features/leaf/leaf_action_executor.dart';

void main() {
  group('parseLeafActionDate', () {
    test('date-only ISO strings parse as local calendar days', () {
      final parsed = parseLeafActionDate('2025-06-12');
      expect(parsed, isNotNull);
      expect(parsed!.year, 2025);
      expect(parsed.month, 6);
      expect(parsed.day, 12);
      expect(parsed.isUtc, isFalse);
    });
  });

  group('linkedSplitEntryIdFromLeafActionData', () {
    test('prefers linked_split_entry_id', () {
      expect(
        linkedSplitEntryIdFromLeafActionData({
          'linked_split_entry_id': 'entry-a',
          'split_entry_id': 'entry-b',
        }),
        'entry-a',
      );
    });

    test('accepts split_entry_id when linked_split_entry_id absent', () {
      expect(
        linkedSplitEntryIdFromLeafActionData({'split_entry_id': ' entry-x '}),
        'entry-x',
      );
    });

    test('accepts camelCase keys', () {
      expect(
        linkedSplitEntryIdFromLeafActionData({'linkedSplitEntryId': 'e1'}),
        'e1',
      );
      expect(
        linkedSplitEntryIdFromLeafActionData({'splitEntryId': 'e2'}),
        'e2',
      );
    });

    test('ignores split_person_id so person ids are not stored as entry ids', () {
      expect(
        linkedSplitEntryIdFromLeafActionData({'split_person_id': 'person-1'}),
        isNull,
      );
    });

    test('returns null for empty strings', () {
      expect(
        linkedSplitEntryIdFromLeafActionData({'linked_split_entry_id': '  '}),
        isNull,
      );
    });
  });
}
