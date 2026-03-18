import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leko/data/db/leko_database.dart';
import 'package:leko/data/repositories/categories_repository.dart';
import 'package:leko/domain/models/enums.dart';
import 'package:leko/domain/services/category_service.dart';

void main() {
  late LekoDatabase db;
  late CategoriesRepository repo;
  late CategoryService service;

  setUp(() async {
    db = LekoDatabase.forTesting(NativeDatabase.memory());
    repo = DriftCategoriesRepository(db);
    service = CategoryService(repo);
  });

  tearDown(() => db.close());

  group('category uniqueness', () {
    test('empty name is invalid', () async {
      final err = await service.validateName('');
      expect(err, isNotNull);
      expect(err, contains('empty'));
    });

    test('whitespace-only name is invalid', () async {
      final err = await service.validateName('   ');
      expect(err, isNotNull);
    });

    test('new unique name passes', () async {
      final err = await service.validateName('Travel');
      expect(err, isNull);
    });

    test('duplicate name fails', () async {
      await service.create(name: 'Travel', defaultLabel: SpendLabel.orange);
      final err = await service.validateName('Travel');
      expect(err, isNotNull);
      expect(err, contains('already exists'));
    });

    test('duplicate detected against seeded system categories', () async {
      final err = await service.validateName('Groceries');
      expect(err, isNotNull);
    });

    test('editing own name is allowed (excludeId)', () async {
      final id = await service.create(
        name: 'Travel',
        defaultLabel: SpendLabel.orange,
      );
      final err = await service.validateName('Travel', excludeId: id);
      expect(err, isNull);
    });

    test('editing to another existing name fails', () async {
      await service.create(name: 'Travel', defaultLabel: SpendLabel.orange);
      final id2 = await service.create(
        name: 'Gifts',
        defaultLabel: SpendLabel.red,
      );
      final err = await service.validateName('Travel', excludeId: id2);
      expect(err, isNotNull);
    });
  });

  group('CRUD', () {
    test('create returns id and category is retrievable', () async {
      final id = await service.create(
        name: 'Pets',
        defaultLabel: SpendLabel.orange,
      );
      expect(id, isNotEmpty);

      final cat = await repo.getById(id);
      expect(cat.name, 'Pets');
      expect(cat.defaultLabel, 'orange');
      expect(cat.isSystem, false);
    });

    test('update changes name and label', () async {
      final id = await service.create(
        name: 'Pets',
        defaultLabel: SpendLabel.orange,
      );
      await service.update(
        id: id,
        name: 'Pet Care',
        defaultLabel: SpendLabel.green,
      );
      final cat = await repo.getById(id);
      expect(cat.name, 'Pet Care');
      expect(cat.defaultLabel, 'green');
    });

    test('delete removes category', () async {
      final id = await service.create(
        name: 'Temp',
        defaultLabel: SpendLabel.red,
      );
      await service.delete(id);
      final all = await repo.getAll();
      expect(all.any((c) => c.id == id), false);
    });
  });

  group('LabelRules', () {
    test('defaultForCategory green', () async {
      final id = await service.create(
        name: 'Test',
        defaultLabel: SpendLabel.green,
      );
      final cat = await repo.getById(id);
      expect(LabelRules.defaultForCategory(cat), SpendLabel.green);
    });

    test('defaultForCategory orange', () async {
      final id = await service.create(
        name: 'Test2',
        defaultLabel: SpendLabel.orange,
      );
      final cat = await repo.getById(id);
      expect(LabelRules.defaultForCategory(cat), SpendLabel.orange);
    });

    test('defaultForCategory red', () async {
      final id = await service.create(
        name: 'Test3',
        defaultLabel: SpendLabel.red,
      );
      final cat = await repo.getById(id);
      expect(LabelRules.defaultForCategory(cat), SpendLabel.red);
    });

    test('resolveLabel returns default when no override', () async {
      final id = await service.create(
        name: 'Foo',
        defaultLabel: SpendLabel.orange,
      );
      final cat = await repo.getById(id);
      final resolved = LabelRules.resolveLabel(category: cat);
      expect(resolved, SpendLabel.orange);
    });

    test('resolveLabel returns override when provided', () async {
      final id = await service.create(
        name: 'Bar',
        defaultLabel: SpendLabel.green,
      );
      final cat = await repo.getById(id);
      final resolved = LabelRules.resolveLabel(
        category: cat,
        userOverride: SpendLabel.red,
      );
      expect(resolved, SpendLabel.red);
    });
  });
}
