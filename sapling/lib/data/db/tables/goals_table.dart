import 'package:drift/drift.dart';

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get targetAmount => real()();
  DateTimeColumn get targetDate => dateTime()();
  TextColumn get savingStyle =>
      text().withDefault(const Constant('natural'))();
  IntColumn get priorityOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
