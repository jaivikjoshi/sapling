import 'package:drift/drift.dart';

@TableIndex(name: 'idx_bills_next_due', columns: {#nextDueDate})
class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get frequency =>
      text().withDefault(const Constant('monthly'))();
  DateTimeColumn get nextDueDate => dateTime()();
  TextColumn get categoryId => text()();
  TextColumn get defaultLabel =>
      text().withDefault(const Constant('green'))();
  BoolColumn get autopay =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get reminderLeadTimeDays =>
      integer().withDefault(const Constant(3))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
