import 'dart:async';

/// Serializes bill-linked expense writes within a single app process.
///
/// Prevents duplicate linked expenses when [BillAutoPoster] and
/// [BillsService.markPaid] overlap on the same bill.
class BillExpenseLock {
  static final _chains = <String, Future<void>>{};

  static Future<T> run<T>(String billId, Future<T> Function() action) async {
    final previous = _chains[billId] ?? Future<void>.value();
    final completer = Completer<void>();
    final current = previous.then((_) => completer.future);
    _chains[billId] = current;
    await previous;
    try {
      return await action();
    } finally {
      completer.complete();
      if (identical(_chains[billId], current)) {
        _chains.remove(billId);
      }
    }
  }
}
