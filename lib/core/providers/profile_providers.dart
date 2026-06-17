import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/profile_service.dart';
import 'auth_providers.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return ProfileService(null);
  return ProfileService(ref.watch(supabaseClientProvider));
});
