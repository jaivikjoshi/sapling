import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sapling/data/db/sapling_database.dart';
import 'package:sapling/data/repositories/goals_repository.dart';
import 'package:sapling/data/repositories/settings_repository.dart';
import 'package:sapling/domain/models/enums.dart';
import 'package:sapling/domain/services/goals_service.dart';

void main() {
  late SaplingDatabase db;
  late GoalsRepository goalsRepo;
  late SettingsRepository settingsRepo;
  late GoalsService service;

  setUp(() {
    db = SaplingDatabase.forTesting(NativeDatabase.memory());
    goalsRepo = DriftGoalsRepository(db);
    settingsRepo = DriftSettingsRepository(db);
    service = GoalsService(goalsRepo, settingsRepo);
  });

  tearDown(() => db.close());

  group('GoalsService validation', () {
    test('validateName rejects empty', () {
      expect(GoalsService.validateName(''), isA<String>());
      expect(GoalsService.validateName('  '), isA<String>());
    });

    test('validateName accepts non-empty', () {
      expect(GoalsService.validateName('Trip'), equals(null));
    });

    test('validateAmount rejects zero or negative', () {
      expect(GoalsService.validateAmount(0), isA<String>());
      expect(GoalsService.validateAmount(-10), isA<String>());
      expect(GoalsService.validateAmount(null), isA<String>());
    });

    test('validateAmount accepts positive', () {
      expect(GoalsService.validateAmount(100), equals(null));
    });

    test('validateDate rejects past dates', () {
      expect(GoalsService.validateDate(DateTime(2020, 1, 1)), isA<String>());
    });

    test('validateDate accepts future dates', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(GoalsService.validateDate(future), equals(null));
    });
  });

  group('GoalsService CRUD', () {
    test('create and list goals', () async {
      final id = await service.create(
        name: 'Vacation',
        targetAmount: 5000,
        targetDate: DateTime.now().add(const Duration(days: 180)),
        savingStyle: SavingStyle.natural,
      );

      final goals = await goalsRepo.getAll();
      expect(goals.length, 1);
      expect(goals.first.id, id);
      expect(goals.first.name, 'Vacation');
    });

    test('update goal changes fields', () async {
      final id = await service.create(
        name: 'Car',
        targetAmount: 10000,
        targetDate: DateTime.now().add(const Duration(days: 365)),
        savingStyle: SavingStyle.easy,
      );

      await service.update(
        id: id,
        name: 'New Car',
        targetAmount: 12000,
        targetDate: DateTime.now().add(const Duration(days: 400)),
        savingStyle: SavingStyle.aggressive,
      );

      final goal = await goalsRepo.getById(id);
      expect(goal.name, 'New Car');
      expect(goal.targetAmount, 12000);
      expect(goal.savingStyle, 'aggressive');
    });

    test('archive hides from active list', () async {
      final id = await service.create(
        name: 'Phone',
        targetAmount: 1500,
        targetDate: DateTime.now().add(const Duration(days: 90)),
        savingStyle: SavingStyle.natural,
      );

      await service.archive(id);
      final active = await goalsRepo.getAll();
      expect(active, isEmpty);
    });

    test('delete removes goal permanently', () async {
      final id = await service.create(
        name: 'Temp',
        targetAmount: 100,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        savingStyle: SavingStyle.easy,
      );

      await service.delete(id);
      final goals = await goalsRepo.getAll();
      expect(goals, isEmpty);
    });
  });

  group('GoalsService primary goal', () {
    test('setPrimaryGoal stores in settings', () async {
      final id = await service.create(
        name: 'Trip',
        targetAmount: 3000,
        targetDate: DateTime.now().add(const Duration(days: 90)),
        savingStyle: SavingStyle.natural,
      );

      await service.setPrimaryGoal(id);
      final settings = await settingsRepo.get();
      expect(settings.primaryGoalId, id);
    });

    test('clearPrimaryGoal nulls the setting', () async {
      final id = await service.create(
        name: 'Fund',
        targetAmount: 2000,
        targetDate: DateTime.now().add(const Duration(days: 60)),
        savingStyle: SavingStyle.aggressive,
      );

      await service.setPrimaryGoal(id);
      await service.clearPrimaryGoal();
      final settings = await settingsRepo.get();
      expect(settings.primaryGoalId, equals(null));
    });
  });
}
