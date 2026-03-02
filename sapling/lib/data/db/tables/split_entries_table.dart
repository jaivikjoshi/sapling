import 'package:drift/drift.dart';

class SplitEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text()();
  RealColumn get totalAmount => real()();
  TextColumn get paidBy => text()();
  TextColumn get linkToExpenseTransactionId => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('open'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
