import 'package:drift/drift.dart';

class SplitShares extends Table {
  TextColumn get id => text()();
  TextColumn get splitEntryId => text()();
  TextColumn get personId => text()();
  RealColumn get shareAmount => real()();

  @override
  Set<Column> get primaryKey => {id};
}
