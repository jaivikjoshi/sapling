/// Lightweight snapshot for the home screen widget. JSON-serializable, small payload.
class DailySnapshot {
  final double todayAllowance;
  final double behindAmount;
  final double? primaryGoalProgress;
  final String treeStage;
  final String closeoutStatus;
  final DateTime timestamp;

  const DailySnapshot({
    required this.todayAllowance,
    required this.behindAmount,
    this.primaryGoalProgress,
    required this.treeStage,
    required this.closeoutStatus,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'todayAllowance': todayAllowance,
        'behindAmount': behindAmount,
        'primaryGoalProgress': primaryGoalProgress,
        'treeStage': treeStage,
        'closeoutStatus': closeoutStatus,
        'timestamp': timestamp.toIso8601String(),
      };

  static DailySnapshot? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final ts = DateTime.tryParse(json['timestamp'] as String? ?? '');
    if (ts == null) return null;
    return DailySnapshot(
      todayAllowance: (json['todayAllowance'] as num?)?.toDouble() ?? 0,
      behindAmount: (json['behindAmount'] as num?)?.toDouble() ?? 0,
      primaryGoalProgress: (json['primaryGoalProgress'] as num?)?.toDouble(),
      treeStage: json['treeStage'] as String? ?? 'seedling',
      closeoutStatus: json['closeoutStatus'] as String? ?? '',
      timestamp: ts,
    );
  }
}
