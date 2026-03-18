import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/leko_database.dart';

final databaseProvider = Provider<LekoDatabase>((ref) {
  final db = LekoDatabase();
  ref.onDispose(() => db.close());
  return db;
});
