import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/core/utils/enum_serialization.dart';
import 'package:sapling/data/db/sapling_database.dart';
import 'package:sapling/data/repositories/recurring_income_repository.dart';
import 'package:sapling/data/repositories/scheduler_metadata_repository.dart';
import 'package:sapling/data/repositories/settings_repository.dart';
import 'package:sapling/domain/models/enums.dart';
import 'package:sapling/domain/schedulers/cycle_boundary_watcher.dart';

void main() {
  late SaplingDatabase db;
  late SchedulerMetadataRepository metadataRepo;
  late SettingsRepository settingsRepo;
  late RecurringIncomeRepository incomeRepo;
  late CycleBoundaryWatcher watcher;

  setUp(() async {
    db = SaplingDatabase.forTesting(NativeDatabase.memory());
    metadataRepo = DriftSchedulerMetadataRepository(db);
    settingsRepo = DriftSettingsRepository(db);
    incomeRepo = DriftRecurringIncomeRepository(db);
    watcher = CycleBoundaryWatcher(metadataRepo, settingsRepo, incomeRepo);
  });

  tearDown(() => db.close());

  Future<void> setRollover(RolloverResetType type) async {
    await settingsRepo.update(
          AppSettingsCompanion(
            rolloverResetType: Value(enumToDb(type)),
          ),
        );
  }

  group('CycleBoundaryWatcher', () {
    test('first run stores current cycle start and returns false', () async {
      await setRollover(RolloverResetType.monthly);
      final crossed = await watcher.checkAndUpdate(DateTime(2025, 6, 15));
      expect(crossed, false);
      final stored = await metadataRepo.get('lastCycleStart');
      expect(stored, '2025-06-01');
    });

    test('same day run returns false', () async {
      await setRollover(RolloverResetType.monthly);
      await watcher.checkAndUpdate(DateTime(2025, 6, 15));
      final crossed = await watcher.checkAndUpdate(DateTime(2025, 6, 20));
      expect(crossed, false);
    });

    test('new month returns true (boundary crossed)', () async {
      await setRollover(RolloverResetType.monthly);
      await watcher.checkAndUpdate(DateTime(2025, 6, 15));
      final crossed = await watcher.checkAndUpdate(DateTime(2025, 7, 1));
      expect(crossed, true);
      final stored = await metadataRepo.get('lastCycleStart');
      expect(stored, '2025-07-01');
    });

    test('payday-based cycle uses anchor schedule', () async {
      await setRollover(RolloverResetType.paydayBased);
      await db.into(db.recurringIncomes).insert(
            RecurringIncomesCompanion.insert(
              id: 'anchor',
              name: 'Pay',
              frequency: const Value('biweekly'),
              nextPaydayDate: DateTime(2025, 7, 11),
              paydayBehavior: const Value('confirm_actual_on_payday'),
              isPaydayAnchorEligible: const Value(true),
              isPaydayAnchor: const Value(true),
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
            ),
          );
      final crossed = await watcher.checkAndUpdate(DateTime(2025, 7, 5));
      expect(crossed, false);
      final stored = await metadataRepo.get('lastCycleStart');
      expect(stored, '2025-06-27');
    });
  });
}
