/// Coordinates once-per-day scheduler runs per signed-in user.
///
/// A run is only considered complete after [markFinished] is called with
/// [success] = true. Failed runs are not deduplicated so the next trigger
/// (app resume, rebuild, or user change) can retry.
class SchedulerRunGate {
  String? lastRunDate;
  String? lastUserId;
  bool lastRunSucceeded = false;
  bool running = false;
  bool retryNeeded = false;

  /// Returns true when a new scheduler run should be skipped.
  bool shouldSkip({
    required String today,
    required String? userId,
    bool forceUser = false,
  }) {
    if (running) {
      retryNeeded = true;
      return true;
    }
    if (!forceUser &&
        lastRunSucceeded &&
        lastRunDate == today &&
        lastUserId == userId) {
      return true;
    }
    return false;
  }

  void markStarted() {
    running = true;
  }

  void markFinished({
    required bool success,
    required String today,
    required String? userId,
  }) {
    running = false;
    if (success) {
      lastRunDate = today;
      lastUserId = userId;
      lastRunSucceeded = true;
    } else {
      lastRunSucceeded = false;
    }
  }

  /// If a trigger arrived while [running] was true, consume the flag so the
  /// caller can schedule one follow-up run.
  bool consumeRetryNeeded() {
    if (!retryNeeded) return false;
    retryNeeded = false;
    return true;
  }
}
