import 'package:drift/drift.dart';

class Persons extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get handle => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
