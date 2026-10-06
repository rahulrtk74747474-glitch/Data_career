class EvidenceAttempt {
  const EvidenceAttempt({
    required this.attemptId,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.skillKey,
    required this.score,
    required this.mode,
    required this.companyKey,
    required this.completedAt,
  });

  final int attemptId;
  final String sourceType;
  final String sourceId;
  final String title;
  final String skillKey;
  final int score;
  final String mode;
  final String companyKey;
  final DateTime completedAt;

  factory EvidenceAttempt.fromMap(Map<String, Object?> map) {
    return EvidenceAttempt(
      attemptId: (map['attempt_id'] as num).toInt(),
      sourceType: map['source_type'] as String,
      sourceId: map['source_id'] as String,
      title: map['title'] as String,
      skillKey: map['skill_key'] as String,
      score: (map['score'] as num).toInt(),
      mode: map['mode'] as String,
      companyKey: map['company_key'] as String,
      completedAt: DateTime.parse(map['completed_at'] as String),
    );
  }
}
