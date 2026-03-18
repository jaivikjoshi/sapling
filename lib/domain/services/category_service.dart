import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/db/leko_database.dart';
import '../../data/repositories/categories_repository.dart';
import '../models/enums.dart';

class CategoryService {
  final CategoriesRepository _repo;
  static const _uuid = Uuid();

  CategoryService(this._repo);

  Stream<List<Category>> watchAll() => _repo.watchAll();

  Future<String?> validateName(String name, {String? excludeId}) async {
    if (name.trim().isEmpty) return 'Name cannot be empty.';
    final exists = await _repo.nameExists(name.trim(), excludeId: excludeId);
    if (exists) return 'A category named "$name" already exists.';
    return null;
  }

  Future<String> create({
    required String name,
    required SpendLabel defaultLabel,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _repo.insert(CategoriesCompanion.insert(
      id: id,
      name: name.trim(),
      defaultLabel: Value(defaultLabel.name),
      isSystem: const Value(false),
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }

  Future<void> update({
    required String id,
    required String name,
    required SpendLabel defaultLabel,
  }) async {
    await _repo.updateById(
      id,
      CategoriesCompanion(
        name: Value(name.trim()),
        defaultLabel: Value(defaultLabel.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) => _repo.deleteById(id);
}

abstract final class LabelRules {
  static SpendLabel defaultForCategory(Category category) {
    return switch (category.defaultLabel) {
      'orange' => SpendLabel.orange,
      'red' => SpendLabel.red,
      _ => SpendLabel.green,
    };
  }

  static SpendLabel resolveLabel({
    required Category category,
    SpendLabel? userOverride,
  }) {
    return userOverride ?? defaultForCategory(category);
  }
}
