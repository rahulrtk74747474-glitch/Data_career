import '../models/capstone.dart';
import 'sql_result_grader.dart';

class CapstoneScore {
  const CapstoneScore({
    required this.cleaning,
    required this.sql,
    required this.statistics,
    required this.kpi,
    required this.dashboard,
    required this.recommendation,
  });

  final int cleaning;
  final int sql;
  final int statistics;
  final int kpi;
  final int dashboard;
  final int recommendation;

  int get total =>
      cleaning + sql + statistics + kpi + dashboard + recommendation;
}

class CapstoneScoringService {
  const CapstoneScoringService._();

  static CapstoneScore score({
    required CapstoneDefinition definition,
    required Set<String> cleaningSelections,
    required List<Map<String, Object?>> sqlRows,
    required String statisticsAnswer,
    required String kpiAnswer,
    required String dashboardAnswer,
    required String recommendationAnswer,
  }) {
    final cleaningCorrect = _sameSet(
      cleaningSelections,
      definition.cleaningExpectedSelections.toSet(),
    );
    final sqlCorrect = SqlResultGrader.grade(
      actualRows: sqlRows,
      expectedRows: definition.sqlExpectedRows,
    ).isCorrect;
    final kpiValue = double.tryParse(
      kpiAnswer.trim().replaceAll('%', '').replaceAll(',', ''),
    );
    final kpiCorrect = kpiValue != null &&
        (kpiValue - definition.kpiExpected).abs() <=
            definition.kpiTolerance;

    return CapstoneScore(
      cleaning: cleaningCorrect ? definition.weight('cleaning') : 0,
      sql: sqlCorrect ? definition.weight('sql') : 0,
      statistics: statisticsAnswer == definition.statisticsExpected
          ? definition.weight('statistics')
          : 0,
      kpi: kpiCorrect ? definition.weight('kpi') : 0,
      dashboard: dashboardAnswer == definition.dashboardExpected
          ? definition.weight('dashboard')
          : 0,
      recommendation:
          recommendationAnswer == definition.recommendationExpected
              ? definition.weight('recommendation')
              : 0,
    );
  }

  static int normalizedComponentScore(int earned, int possible) {
    if (possible <= 0) return 0;
    return ((earned / possible) * 100).round().clamp(0, 100).toInt();
  }

  static bool _sameSet(Set<String> a, Set<String> b) {
    return a.length == b.length && a.containsAll(b);
  }
}
