class InterviewResult {
  const InterviewResult({
    required this.roundKey,
    required this.completedAt,
    required this.bestScore,
    required this.latestScore,
    required this.attempts,
    required this.lastMode,
  });

  final String roundKey;
  final DateTime completedAt;
  final int bestScore;
  final int latestScore;
  final int attempts;
  final String lastMode;

  factory InterviewResult.fromMap(Map<String, Object?> map) {
    return InterviewResult(
      roundKey: map['round_key'] as String,
      completedAt: DateTime.parse(map['completed_at'] as String),
      bestScore: (map['best_score'] as num).toInt(),
      latestScore: (map['latest_score'] as num).toInt(),
      attempts: (map['attempts'] as num).toInt(),
      lastMode: map['last_mode'] as String,
    );
  }
}
