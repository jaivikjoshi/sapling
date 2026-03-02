import 'package:drift/drift.dart';

@TableIndex(name: 'idx_transactions_date', columns: {#date})
@TableIndex(name: 'idx_transactions_type_date', columns: {#type, #date})
@TableIndex(name: 'idx_transactions_linked_bill', columns: {#linkedBillId})
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get label => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get linkedBillId => text().nullable()();
  TextColumn get linkedRecurringIncomeId => text().nullable()();
  TextColumn get linkedSplitEntryId => text().nullable()();
  TextColumn get incomePostingType => text().nullable()();
  TextColumn get source => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
