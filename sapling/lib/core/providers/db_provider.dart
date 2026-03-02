import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/sapling_database.dart';

final databaseProvider = Provider<SaplingDatabase>((ref) {
  final db = SaplingDatabase();
  ref.onDispose(() => db.close());
  return db;
});
