/// Tracks app-open scheduler runs and serializes overlap.
///
/// Schedulers must not run while [userId] is null because repositories fall
/// back to the local store before Supabase session restore finishes. A run is
/// only recorded after it succeeds, so transient failures can retry later.
class SchedulerRunCoordinator {
  String? lastRunDate;
  String? lastUserId;
  bool running = false;
  bool rerunPending = false;

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

  void markRunStarted() {
    running = true;
  }

  void markRunFinished({required String today, required String userId}) {
    lastRunDate = today;
    lastUserId = userId;
    running = false;
  }

  void markRunEndedWithoutSuccess() {
    running = false;
  }

  bool consumeRerunPending() {
    if (!rerunPending) return false;
    rerunPending = false;
    return true;
  }
}
