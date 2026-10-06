class TaskPerformance {
  const TaskPerformance({
    required this.taskId,
    required this.title,
    required this.skillKey,
    required this.difficulty,
    required this.bestScore,
    required this.attempts,
    required this.lastCompletedAt,
  });

  final String taskId;
  final String title;
  final String skillKey;
  final String difficulty;
  final int bestScore;
  final int attempts;
  final DateTime lastCompletedAt;

  factory TaskPerformance.fromMap(Map<String, Object?> map) {
    return TaskPerformance(
      taskId: map['task_id'] as String,
      title: map['title'] as String,
      skillKey: map['skill_key'] as String,
      difficulty: map['difficulty'] as String,
      bestScore: (map['best_score'] as num).toInt(),
      attempts: (map['attempts'] as num).toInt(),
      lastCompletedAt: DateTime.parse(map['last_completed_at'] as String),
    );
  }
}
