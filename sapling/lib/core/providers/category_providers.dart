import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/categories_repository.dart';
import '../../domain/services/category_service.dart';
import 'db_provider.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) {
  final repo = CategoriesRepository(ref.watch(databaseProvider));
  return CategoryService(repo);
});
