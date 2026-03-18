import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/settings_table.dart';
import 'tables/transactions_table.dart';
import 'tables/categories_table.dart';
import 'tables/goals_table.dart';
import 'tables/recurring_incomes_table.dart';
import 'tables/bills_table.dart';
import 'tables/persons_table.dart';
import 'tables/split_entries_table.dart';
import 'tables/split_shares_table.dart';
import 'tables/daily_closeouts_table.dart';
import 'tables/recovery_plans_table.dart';
import 'tables/scheduler_metadata_table.dart';

part 'leko_database.g.dart';

@DriftDatabase(tables: [
  AppSettings,
  Transactions,
  Categories,
  Goals,
  RecurringIncomes,
  Bills,
  Persons,
  SplitEntries,
  SplitShares,
  DailyCloseouts,
  RecoveryPlans,
  SchedulerMetadata,
])
class LekoDatabase extends _$LekoDatabase {
  LekoDatabase() : super(_openConnection());

  LekoDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaults();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(schedulerMetadata);
          }
        },
      );

  Future<void> _seedDefaults() async {
    await into(appSettings).insert(
      AppSettingsCompanion.insert(),
    );
    await _seedSystemCategories();
  }

  Future<void> _seedSystemCategories() async {
    final now = DateTime.now();
    final systemCategories = [
      ('cat_groceries', 'Groceries', 'green'),
      ('cat_rent', 'Rent / Mortgage', 'green'),
      ('cat_utilities', 'Utilities', 'green'),
      ('cat_transport', 'Transportation', 'green'),
      ('cat_dining', 'Dining Out', 'orange'),
      ('cat_entertainment', 'Entertainment', 'orange'),
      ('cat_shopping', 'Shopping', 'red'),
      ('cat_subscriptions', 'Subscriptions', 'orange'),
      ('cat_health', 'Health & Medical', 'green'),
      ('cat_personal', 'Personal Care', 'orange'),
      ('cat_other', 'Other', 'red'),
    ];

    for (final (id, name, label) in systemCategories) {
      await into(categories).insert(CategoriesCompanion.insert(
        id: id,
        name: name,
        defaultLabel: Value(label),
        isSystem: const Value(true),
        createdAt: now,
        updatedAt: now,
      ));
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'leko.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
