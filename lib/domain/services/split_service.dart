import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/leko_database.dart';
import '../../data/repositories/split_entries_repository.dart';
import '../../data/repositories/split_shares_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../data/repositories/persons_repository.dart';

/// "you" as paidBy or as personId in shares (your share).
const String kSplitPaidByYou = 'you';

class PersonBalance {
  final String personId;
  final double owedToYou;
  final double youOwe;

  const PersonBalance({
    required this.personId,
    required this.owedToYou,
    required this.youOwe,
  });

  double get netOwedToYou => owedToYou - youOwe;
}

class SplitService {
  final SplitEntriesRepository _entriesRepo;
  final SplitSharesRepository _sharesRepo;
  final TransactionsRepository _txnRepo;
  final PersonsRepository _personsRepo;
  static const _uuid = Uuid();

  SplitService(
    this._entriesRepo,
    this._sharesRepo,
    this._txnRepo,
    this._personsRepo,
  );

  Future<String> createSplit({
    required String description,
    required double totalAmount,
    required String paidBy,
    required List<({String personId, double shareAmount})> shares,
  }) async {
    if (totalAmount <= 0) throw ArgumentError('totalAmount must be > 0');
    final sum = shares.fold<double>(0, (s, e) => s + e.shareAmount);
    if ((sum - totalAmount).abs() > 0.01) {
      throw ArgumentError('Sum of shares must equal totalAmount');
    }
    for (final s in shares) {
      if (s.shareAmount <= 0) throw ArgumentError('Each share must be > 0');
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    await _entriesRepo.insert(SplitEntriesCompanion.insert(
      id: id,
      date: now,
      description: description,
      totalAmount: totalAmount,
      paidBy: paidBy,
      status: Value('open'),
      createdAt: now,
      updatedAt: now,
    ));

    final companions = shares
        .map((s) => SplitSharesCompanion.insert(
              id: _uuid.v4(),
              splitEntryId: id,
              personId: s.personId,
              shareAmount: s.shareAmount,
            ))
        .toList();
    await _sharesRepo.insertAll(companions);
    return id;
  }

  /// Returns balances per person for open splits only.
  Future<Map<String, PersonBalance>> computeBalancesByPerson() async {
    final open = await _entriesRepo.getOpen();
    final Map<String, double> owedToYou = {};
    final Map<String, double> youOwe = {};

    for (final entry in open) {
      final shares = await _sharesRepo.getBySplitEntryId(entry.id);
      final paidByYou = entry.paidBy == kSplitPaidByYou;

      for (final share in shares) {
        if (share.personId == kSplitPaidByYou) {
          if (!paidByYou) {
            youOwe[entry.paidBy] =
                (youOwe[entry.paidBy] ?? 0) + share.shareAmount;
          }
        } else {
          if (paidByYou) {
            owedToYou[share.personId] =
                (owedToYou[share.personId] ?? 0) + share.shareAmount;
          }
        }
      }
    }

    final allPersonIds = {...owedToYou.keys, ...youOwe.keys};
    return Map.fromEntries(allPersonIds.map((id) {
      return MapEntry(
        id,
        PersonBalance(
          personId: id,
          owedToYou: owedToYou[id] ?? 0,
          youOwe: youOwe[id] ?? 0,
        ),
      );
    }));
  }

  Future<void> markSettled(String splitEntryId) async {
    final entry = await _entriesRepo.getById(splitEntryId);
    if (entry == null) return;
    final now = DateTime.now();
    await _entriesRepo.updateById(
      splitEntryId,
      SplitEntriesCompanion(status: Value('settled'), updatedAt: Value(now)),
    );
  }

  /// Links an expense transaction to a split and vice versa.
  Future<void> linkExpenseToSplit(String expenseId, String splitEntryId) async {
    final txn = await _txnRepo.getByIdOrNull(expenseId);
    final entry = await _entriesRepo.getById(splitEntryId);
    if (txn == null || entry == null) return;
    if (txn.type != 'expense') return;

    final now = DateTime.now();
    await _txnRepo.updateById(
      expenseId,
      txn.copyWith(
        linkedSplitEntryId: Value(splitEntryId),
        updatedAt: now,
      ),
    );
    await _entriesRepo.updateById(
      splitEntryId,
      SplitEntriesCompanion(
        linkToExpenseTransactionId: Value(expenseId),
        updatedAt: Value(now),
      ),
    );
  }

  /// Call when user confirms "Update linked split too?" after editing expense.
  /// Updates split total to newAmount and rescales shares proportionally (keeps ratios).
  Future<void> updateSplitFromExpenseAmount(
      String splitEntryId, double newAmount) async {
    if (newAmount <= 0) return;
    final entry = await _entriesRepo.getById(splitEntryId);
    if (entry == null) return;

    final shares = await _sharesRepo.getBySplitEntryId(splitEntryId);
    if (shares.isEmpty) return;

    final ratio = newAmount / entry.totalAmount;
    final now = DateTime.now();
    await _entriesRepo.updateById(
      splitEntryId,
      SplitEntriesCompanion(
        totalAmount: Value(newAmount),
        updatedAt: Value(now),
      ),
    );
    for (final s in shares) {
      final newShare = (s.shareAmount * ratio * 100).round() / 100;
      await _sharesRepo.updateShareAmount(s.id, newShare);
    }
  }

  /// Returns splitEntryId if the expense is linked to a split, else null.
  Future<String?> getLinkedSplitEntryId(String expenseId) async {
    final txn = await _txnRepo.getByIdOrNull(expenseId);
    return txn?.linkedSplitEntryId;
  }

  Stream<List<SplitEntry>> watchOpenSplits() => _entriesRepo.watchOpen();

  Stream<List<SplitEntry>> watchOpenSplitsForPerson(String personId) {
    return _entriesRepo.watchOpen().asyncMap((splits) async {
      final result = <SplitEntry>[];
      for (final s in splits) {
        if (s.paidBy == personId) {
          result.add(s);
          continue;
        }
        final shares = await _sharesRepo.getBySplitEntryId(s.id);
        if (shares.any((sh) => sh.personId == personId)) result.add(s);
      }
      return result;
    });
  }

  Stream<Map<String, PersonBalance>> watchBalancesByPerson() {
    return _entriesRepo.watchOpen().asyncMap((_) => computeBalancesByPerson());
  }

  Future<SplitEntry?> getSplitById(String id) => _entriesRepo.getById(id);

  Future<List<SplitShare>> getSharesForSplit(String splitEntryId) =>
      _sharesRepo.getBySplitEntryId(splitEntryId);

  Future<List<Person>> getPersons() => _personsRepo.getAll();

  Stream<List<Person>> watchPersons() => _personsRepo.watchAll();
}
