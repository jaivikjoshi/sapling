import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/enum_serialization.dart';
import '../../data/db/leko_database.dart';
import '../../data/repositories/goals_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../models/enums.dart';

class GoalsService {
  final GoalsRepository _goalsRepo;
  final SettingsRepository _settingsRepo;
  static const _uuid = Uuid();

  GoalsService(this._goalsRepo, this._settingsRepo);

  Stream<List<Goal>> watchAll() => _goalsRepo.watchAll();
  Stream<List<Goal>> watchArchived() => _goalsRepo.watchArchived();
  Future<Goal> getById(String id) => _goalsRepo.getById(id);

  static String? validateName(String name) {
    if (name.trim().isEmpty) return 'Goal name is required.';
    return null;
  }

  static String? validateAmount(double? amount) {
    if (amount == null || amount <= 0) return 'Target amount must be > 0.';
    return null;
  }

  static String? validateDate(DateTime? date) {
    if (date == null) return 'Target date is required.';
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    if (!date.isAfter(todayStart)) return 'Target date must be in the future.';
    return null;
  }

  Future<String> create({
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    required SavingStyle savingStyle,
    int priorityOrder = 0,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _goalsRepo.insert(GoalsCompanion.insert(
      id: id,
      name: name.trim(),
      targetAmount: targetAmount,
      targetDate: targetDate,
      savingStyle: Value(enumToDb(savingStyle)),
      priorityOrder: Value(priorityOrder),
      createdAt: now,
      updatedAt: now,
    ));
    return id;
  }

  Future<void> update({
    required String id,
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    required SavingStyle savingStyle,
    int? priorityOrder,
  }) async {
    await _goalsRepo.updateById(
      id,
      GoalsCompanion(
        name: Value(name.trim()),
        targetAmount: Value(targetAmount),
        targetDate: Value(targetDate),
        savingStyle: Value(enumToDb(savingStyle)),
        priorityOrder: priorityOrder != null
            ? Value(priorityOrder)
            : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> archive(String id) async {
    await _goalsRepo.updateById(
      id,
      GoalsCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) => _goalsRepo.deleteById(id);

  Future<void> setPrimaryGoal(String goalId) async {
    await _settingsRepo.update(
      AppSettingsCompanion(primaryGoalId: Value(goalId)),
    );
  }

  Future<void> clearPrimaryGoal() async {
    await _settingsRepo.update(
      const AppSettingsCompanion(primaryGoalId: Value(null)),
    );
  }
}
