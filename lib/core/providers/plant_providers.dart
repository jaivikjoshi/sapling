import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/plant_repository.dart';
import '../../data/repositories_supabase/supabase_plant_repository.dart';
import '../../domain/models/plant_state.dart';
import '../../domain/services/plant_service.dart';
import 'allowance_providers.dart';
import 'auth_providers.dart';
import 'closeout_providers.dart';
import 'settings_providers.dart';

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    // Fallback: in-memory stub until authenticated.
    return _InMemoryPlantRepository();
  }
  return SupabasePlantRepository(ref.watch(supabaseClientProvider), userId);
});

final plantServiceProvider = Provider<PlantService>((ref) {
  return PlantService(
    ref.watch(allowanceEngineProvider),
    ref.watch(closeoutServiceProvider),
  );
});

/// Main reactive provider for the widget.
final plantStateProvider = StreamProvider<PlantState>((ref) {
  return ref.watch(plantRepositoryProvider).watch().map(
        (state) => state ?? PlantState.initial(),
      );
});

/// Triggers a plant update (evaluate missed days) and persists the result.
/// Call this on app open or after a closeout.
final plantUpdateProvider = FutureProvider<PlantState>((ref) async {
  final repo = ref.watch(plantRepositoryProvider);
  final service = ref.watch(plantServiceProvider);
  final settings = ref.watch(settingsStreamProvider).valueOrNull;

  if (settings == null) return PlantState.initial();

  var current = await repo.get() ?? PlantState.initial();
  final updated = await service.updatePlant(current: current, settings: settings);

  if (updated != current) {
    await repo.upsert(updated);
  }
  return updated;
});

// ── Fallback in-memory repo (for unauthenticated / testing) ──

class _InMemoryPlantRepository implements PlantRepository {
  PlantState? _state;

  @override
  Future<PlantState?> get() async => _state;

  @override
  Future<void> upsert(PlantState state) async => _state = state;

  @override
  Stream<PlantState?> watch() => Stream.value(_state);
}
