import 'package:drift/drift.dart';
import '../db/sapling_database.dart';

class SettingsRepository {
  final SaplingDatabase _db;

  SettingsRepository(this._db);

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
