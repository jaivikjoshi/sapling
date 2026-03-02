import 'package:drift/drift.dart';

class RecoveryPlans extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get triggerTransactionId => text()();
  RealColumn get overspendAmount => real()();
  TextColumn get planType => text()();
  TextColumn get parameters => text().withDefault(const Constant('{}'))();
  TextColumn get status =>
      text().withDefault(const Constant('active'))();

  @override
  Set<Column> get primaryKey => {id};
}
