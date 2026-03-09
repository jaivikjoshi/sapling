import '../../domain/models/plant_state.dart';

/// Abstract repository for persisting the user's plant state.
abstract class PlantRepository {
  /// Get the current plant state, or null if none exists yet.
  Future<PlantState?> get();

  /// Insert or update the plant state.
  Future<void> upsert(PlantState state);

  /// Reactive stream of plant state changes.
  Stream<PlantState?> watch();
}
