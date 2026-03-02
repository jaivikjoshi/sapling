import 'package:drift/drift.dart';

@TableIndex(
  name: 'idx_recurring_incomes_next_payday',
  columns: {#nextPaydayDate},
)
class RecurringIncomes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get frequency =>
      text().withDefault(const Constant('monthly'))();
  DateTimeColumn get nextPaydayDate => dateTime()();
  RealColumn get expectedAmount => real().nullable()();
  TextColumn get paydayBehavior =>
      text().withDefault(const Constant('confirm_actual_on_payday'))();
  BoolColumn get isPaydayAnchorEligible =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isPaydayAnchor =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get reminderTime => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
