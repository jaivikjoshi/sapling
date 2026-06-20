import 'dart:async';

/// Serializes bill-payment mutations per [billId].
///
/// [BillsService.markPaid] and [BillAutoPoster] both perform check-then-insert
/// flows. Without a lock, overlapping calls can insert duplicate linked
/// expenses before either write is visible to the other.
class BillPaymentLock {
  static final _chains = <String, Future<void>>{};

  static Future<T> runForBill<T>(
    String billId,
    Future<T> Function() action,
  ) async {
    final previous = _chains[billId] ?? Future<void>.value();
    final gate = Completer<void>();
    _chains[billId] = gate.future;
    await previous;
    try {
      return await action();
    } finally {
      gate.complete();
      if (identical(_chains[billId], gate.future)) {
        _chains.remove(billId);
      }
    }
  }
}
