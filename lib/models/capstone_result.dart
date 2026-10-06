class CapstoneResult {
  const CapstoneResult({
    required this.capstoneId,
    required this.completedAt,
    required this.totalScore,
    required this.cleaningScore,
    required this.sqlScore,
    required this.statisticsScore,
    required this.kpiScore,
    required this.dashboardScore,
    required this.recommendationScore,
  });

  final String capstoneId;
  final DateTime completedAt;
  final int totalScore;
  final int cleaningScore;
  final int sqlScore;
  final int statisticsScore;
  final int kpiScore;
  final int dashboardScore;
  final int recommendationScore;

  factory CapstoneResult.fromMap(Map<String, Object?> map) {
    return CapstoneResult(
      capstoneId: map['capstone_id'] as String,
      completedAt: DateTime.parse(map['completed_at'] as String),
      totalScore: (map['total_score'] as num).toInt(),
      cleaningScore: (map['cleaning_score'] as num).toInt(),
      sqlScore: (map['sql_score'] as num).toInt(),
      statisticsScore: (map['statistics_score'] as num).toInt(),
      kpiScore: (map['kpi_score'] as num).toInt(),
      dashboardScore: (map['dashboard_score'] as num).toInt(),
      recommendationScore: (map['recommendation_score'] as num).toInt(),
    );
  }
}
