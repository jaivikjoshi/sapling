import 'package:flutter_test/flutter_test.dart';
import 'package:leko/features/leaf/leaf_action_executor.dart';

void main() {
  group('linkedSplitEntryIdFromLeafActionData', () {
    test('prefers linked_split_entry_id over other keys', () {
      expect(
        linkedSplitEntryIdFromLeafActionData({
          'linked_split_entry_id': 'entry-a',
          'split_entry_id': 'entry-b',
          'split_person_id': 'person-c',
        }),
        'entry-a',
      );
    });

    test('falls back to split_entry_id', () {
      expect(
        linkedSplitEntryIdFromLeafActionData({
          'split_entry_id': 'entry-x',
        }),
        'entry-x',
      );
    });

    test('falls back to legacy split_person_id', () {
      expect(
        linkedSplitEntryIdFromLeafActionData({
          'split_person_id': 'legacy-entry',
        }),
        'legacy-entry',
      );
    });

    test('trims whitespace and ignores empty strings', () {
      expect(
        linkedSplitEntryIdFromLeafActionData({
          'linked_split_entry_id': '  ',
          'split_entry_id': '  real-id  ',
        }),
        'real-id',
      );
    });

    test('returns null when absent or not strings', () {
      expect(linkedSplitEntryIdFromLeafActionData({}), isNull);
      expect(
        linkedSplitEntryIdFromLeafActionData({'linked_split_entry_id': 42}),
        isNull,
      );
    });
  });
}
