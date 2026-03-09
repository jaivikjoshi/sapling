
/// Represents the user's plant growth & health state.
/// Growth is permanent (points only increase, unless prolonged neglect).
/// Health fluctuates with streak.
class PlantState {
  final int growthPoints;
  final int healthScore; // 0–100
  final int longestStreak;
  final int currentStreak;
  final int daysAtZero;
  final DateTime lastEvaluatedDate;

  const PlantState({
    required this.growthPoints,
    required this.healthScore,
    required this.longestStreak,
    required this.currentStreak,
    required this.daysAtZero,
    required this.lastEvaluatedDate,
  });

  /// Factory for a brand-new user who has never been evaluated.
  factory PlantState.initial() => PlantState(
        growthPoints: 0,
        healthScore: 100,
        longestStreak: 0,
        currentStreak: 0,
        daysAtZero: 0,
        lastEvaluatedDate:
            DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      );

  // ── Growth stage (0–6) derived from growthPoints ──

  static const List<int> growthThresholds = [0, 5, 10, 20, 35, 60, 100];

  int get growthStage {
    int stage = 0;
    for (int i = growthThresholds.length - 1; i >= 0; i--) {
      if (growthPoints >= growthThresholds[i]) {
        stage = i;
        break;
      }
    }
    return stage;
  }

  // ── Health stage (0–5) derived from healthScore ──

  int get healthStage {
    if (healthScore >= 80) return 5; // healthy
    if (healthScore >= 60) return 4; // slightly wilted
    if (healthScore >= 40) return 3; // wilted
    if (healthScore >= 20) return 2; // leaf loss
    if (healthScore >= 1) return 1;  // dried
    return 0; // dead
  }

  // ── Milestone flags ──

  bool get hasFlowerBud => growthPoints >= 10;
  bool get hasFlowers => growthPoints >= 20;
  bool get hasFruit => growthPoints >= 60;
  bool get hasBird => longestStreak >= 30;
  bool get hasGlow => longestStreak >= 14;
  bool get hasButterfly => longestStreak >= 60;

  /// Normalized growth progress 0.0–1.0 for smooth rendering.
  double get growthProgress {
    if (growthStage >= 6) return 1.0;
    final lo = growthThresholds[growthStage];
    final hi = growthThresholds[growthStage + 1];
    return ((growthPoints - lo) / (hi - lo)).clamp(0.0, 1.0);
  }

  /// Normalized health 0.0–1.0 for smooth visual effects.
  double get healthNormalized => (healthScore / 100.0).clamp(0.0, 1.0);

  // ── Copyable ──

  PlantState copyWith({
    int? growthPoints,
    int? healthScore,
    int? longestStreak,
    int? currentStreak,
    int? daysAtZero,
    DateTime? lastEvaluatedDate,
  }) {
    return PlantState(
      growthPoints: growthPoints ?? this.growthPoints,
      healthScore: healthScore ?? this.healthScore,
      longestStreak: longestStreak ?? this.longestStreak,
      currentStreak: currentStreak ?? this.currentStreak,
      daysAtZero: daysAtZero ?? this.daysAtZero,
      lastEvaluatedDate: lastEvaluatedDate ?? this.lastEvaluatedDate,
    );
  }

  // ── JSON serialization (for Supabase / Drift) ──

  Map<String, dynamic> toJson() => {
        'growth_points': growthPoints,
        'health_score': healthScore,
        'longest_streak': longestStreak,
        'current_streak': currentStreak,
        'days_at_zero': daysAtZero,
        'last_evaluated_date':
            '${lastEvaluatedDate.year}-${lastEvaluatedDate.month.toString().padLeft(2, '0')}-${lastEvaluatedDate.day.toString().padLeft(2, '0')}',
      };

  factory PlantState.fromJson(Map<String, dynamic> json) {
    final dateStr = json['last_evaluated_date'] as String?;
    DateTime lastDate;
    if (dateStr != null) {
      final parsed = DateTime.tryParse(dateStr);
      lastDate = parsed != null
          ? DateTime(parsed.year, parsed.month, parsed.day)
          : DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    } else {
      lastDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    }

    return PlantState(
      growthPoints: (json['growth_points'] as num?)?.toInt() ?? 0,
      healthScore: (json['health_score'] as num?)?.toInt() ?? 100,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      daysAtZero: (json['days_at_zero'] as num?)?.toInt() ?? 0,
      lastEvaluatedDate: lastDate,
    );
  }

  @override
  String toString() =>
      'PlantState(growth: $growthPoints/stg$growthStage, health: $healthScore/stg$healthStage, '
      'streak: $currentStreak, longest: $longestStreak, daysAt0: $daysAtZero)';
}
