import 'package:flutter_test/flutter_test.dart';
import 'package:leko/domain/services/bill_expense_lock.dart';

void main() {
  group('BillExpenseLock', () {
    test('serializes concurrent work for the same bill', () async {
      final events = <String>[];

      await Future.wait([
        BillExpenseLock.run('bill-1', () async {
          events.add('a-start');
          await Future<void>.delayed(const Duration(milliseconds: 20));
          events.add('a-end');
        }),
        BillExpenseLock.run('bill-1', () async {
          events.add('b-start');
          events.add('b-end');
        }),
      ]);

      expect(events.indexOf('a-start'), lessThan(events.indexOf('a-end')));
      expect(events.indexOf('a-end'), lessThan(events.indexOf('b-start')));
      expect(events, ['a-start', 'a-end', 'b-start', 'b-end']);
    });

    test('does not block unrelated bills', () async {
      final events = <String>[];

      await Future.wait([
        BillExpenseLock.run('bill-1', () async {
          events.add('a-start');
          await Future<void>.delayed(const Duration(milliseconds: 10));
          events.add('a-end');
        }),
        BillExpenseLock.run('bill-2', () async {
          events.add('b-start');
          events.add('b-end');
        }),
      ]);

      expect(events.indexOf('b-start'), lessThan(events.indexOf('a-end')));
    });
  });
}
