import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/profile_service.dart';
import 'auth_providers.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(supabaseClientProvider));
});
