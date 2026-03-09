import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/category_service.dart';
import 'ledger_providers.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) {
  return CategoryService(ref.watch(categoriesRepositoryProvider));
});
