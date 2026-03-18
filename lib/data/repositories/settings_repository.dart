import 'package:drift/drift.dart';

import '../db/leko_database.dart';

/// Interface for settings repository (Drift or Supabase implementation).
abstract class SettingsRepository {
  Future<AppSetting> get();
  Stream<AppSetting> watch();
  Future<void> update(AppSettingsCompanion companion);
  Future<void> markOnboardingComplete();
}

class DriftSettingsRepository implements SettingsRepository {
  final LekoDatabase _db;

  DriftSettingsRepository(this._db);

  Future<AppSetting> get() async {
    return _db.select(_db.appSettings).getSingle();
  }

  Stream<AppSetting> watch() {
    return _db.select(_db.appSettings).watchSingle();
  }

  Future<void> update(AppSettingsCompanion companion) async {
    await (_db.update(_db.appSettings)
          ..where((t) => t.id.equals('singleton')))
        .write(companion);
  }

  Future<void> markOnboardingComplete() async {
    await update(
      const AppSettingsCompanion(onboardingCompleted: Value(true)),
    );
  }
}
