/// Pure helper used by [LekoApp] to decide whether to enqueue the daily
/// scheduler pipeline (cycle boundary, payday/bill auto-post, notifications,
/// widget snapshot).
///
/// When [currentUserId] is null, repositories resolve to local Drift — running
/// schedulers in that window would mutate the wrong backing store.
bool shouldSkipEnqueueDailySchedulers({
  required bool schedulerRunning,
  required String? currentUserId,
  required String todayDateKey,
  required String? lastRunDateKey,
  required String? lastRunUserId,
  required bool forceUserChange,
}) {
  if (schedulerRunning) return true;
  if (currentUserId == null) return true;
  if (!forceUserChange &&
      lastRunDateKey == todayDateKey &&
      lastRunUserId == currentUserId) {
    return true;
  }
  return false;
}
