class BossCaseResult {
  const BossCaseResult({
    required this.caseId,
    required this.completedAt,
    required this.totalScore,
    required this.cleaningScore,
    required this.sqlScore,
    required this.kpiScore,
    required this.chartScore,
    required this.recommendationScore,
  });

  final String caseId;
  final DateTime completedAt;
  final int totalScore;
  final int cleaningScore;
  final int sqlScore;
  final int kpiScore;
  final int chartScore;
  final int recommendationScore;

  factory BossCaseResult.fromMap(Map<String, Object?> map) {
    return BossCaseResult(
      caseId: map['case_id'] as String,
      completedAt: DateTime.parse(map['completed_at'] as String),
      totalScore: (map['total_score'] as num).toInt(),
      cleaningScore: (map['cleaning_score'] as num).toInt(),
      sqlScore: (map['sql_score'] as num).toInt(),
      kpiScore: (map['kpi_score'] as num).toInt(),
      chartScore: (map['chart_score'] as num).toInt(),
      recommendationScore: (map['recommendation_score'] as num).toInt(),
    );
  }
}
