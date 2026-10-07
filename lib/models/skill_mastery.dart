class SkillMastery {
  const SkillMastery({
    required this.skillKey,
    required this.mastery,
    required this.attempts,
    required this.correct,
    required this.nextReviewAt,
  });

  final String skillKey;
  final double mastery;
  final int attempts;
  final int correct;
  final DateTime? nextReviewAt;

  String get displayName {
    switch (skillKey) {
      case 'spreadsheets':
        return 'Spreadsheets';
      case 'sql':
        return 'SQL';
      case 'cleaning':
        return 'Data Cleaning';
      case 'statistics':
        return 'Statistics';
      case 'business':
        return 'Business';
      case 'python':
        return 'Python/Pandas';
      case 'powerbi':
        return 'Power BI';
      default:
        return skillKey;
    }
  }

  String get shortName {
    switch (skillKey) {
      case 'spreadsheets':
        return 'Sheets';
      case 'cleaning':
        return 'Cleaning';
      case 'statistics':
        return 'Stats';
      case 'business':
        return 'Business';
      case 'python':
        return 'Pandas';
      case 'powerbi':
        return 'Power BI';
      default:
        return displayName;
    }
  }

  bool get isWeak => mastery < 60;

  bool isDue(DateTime now) {
    return nextReviewAt != null && !nextReviewAt!.isAfter(now);
  }

  factory SkillMastery.fromMap(Map<String, Object?> map) {
    final nextReviewRaw = map['next_review_at'] as String?;
    return SkillMastery(
      skillKey: map['skill_key'] as String,
      mastery: (map['mastery'] as num).toDouble(),
      attempts: (map['attempts'] as num).toInt(),
      correct: (map['correct_count'] as num).toInt(),
      nextReviewAt:
          nextReviewRaw == null ? null : DateTime.tryParse(nextReviewRaw),
    );
  }
}
