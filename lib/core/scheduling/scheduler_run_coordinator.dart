/// Tracks whether app-open schedulers already ran today and serializes overlap.
///
/// Schedulers must not run while [userId] is null (repositories fall back to
/// local Drift). If a run is already in flight, [requestRun] sets [rerunPending]
/// so the caller can schedule again after the current run finishes.
class SchedulerRunCoordinator {
  String? lastRunDate;
  String? lastUserId;
  bool running = false;
  bool rerunPending = false;

  /// Returns true when a new scheduler run should start now.
  bool requestRun({
    required String today,
    required String? userId,
    bool forceUser = false,
  }) {
    if (userId == null) return false;
    if (running) {
      rerunPending = true;
      return false;
    }
    if (!forceUser && lastRunDate == today && lastUserId == userId) {
      return false;
    }
    return true;
  }

  void markRunStarted() => running = true;

  void markRunFinished({required String today, required String userId}) {
    lastRunDate = today;
    lastUserId = userId;
    running = false;
  }

  void markRunEndedWithoutSuccess() {
    running = false;
  }

  /// Whether a run was skipped while [running] and should be re-attempted.
  bool consumeRerunPending() {
    if (!rerunPending) return false;
    rerunPending = false;
    return true;
  }
}
