import 'dart:math' as math;

import '../models/boss_case.dart';
import 'sql_result_grader.dart';

class BossCaseScore {
  const BossCaseScore({
    required this.cleaning,
    required this.sql,
    required this.kpi,
    required this.chart,
    required this.recommendation,
  });

  final int cleaning;
  final int sql;
  final int kpi;
  final int chart;
  final int recommendation;

  int get total => cleaning + sql + kpi + chart + recommendation;
}

class BossCaseScoringService {
  const BossCaseScoringService._();

  static BossCaseScore score({
    required BossCaseDefinition definition,
    required Set<String> cleaningSelections,
    required List<Map<String, Object?>> sqlRows,
    bool sqlTruncated = false,
    required String kpiAnswer,
    required String chartAnswer,
    required String recommendationAnswer,
  }) {
    final cleaningCorrect = _sameSelections(
      cleaningSelections,
      definition.cleaningExpectedSelections,
    );

    final sqlCorrect = SqlResultGrader.grade(
      actualRows: sqlRows,
      expectedRows: definition.sqlExpectedRows,
      truncated: sqlTruncated,
    ).isCorrect;

    final parsedKpi = double.tryParse(
      kpiAnswer.trim().replaceAll('%', ''),
    );
    final kpiCorrect = parsedKpi != null &&
        (parsedKpi - definition.kpiExpected).abs() <=
            definition.kpiTolerance;

    return BossCaseScore(
      cleaning: cleaningCorrect ? definition.weight('cleaning') : 0,
      sql: sqlCorrect ? definition.weight('sql') : 0,
      kpi: kpiCorrect ? definition.weight('kpi') : 0,
      chart: chartAnswer == definition.chartExpected
          ? definition.weight('chart')
          : 0,
      recommendation:
          recommendationAnswer == definition.recommendationExpected
              ? definition.weight('recommendation')
              : 0,
    );
  }

  static bool _sameSelections(
    Set<String> actual,
    List<String> expected,
  ) {
    if (actual.length != expected.length) return false;
    return actual.containsAll(expected);
  }

  static int normalizedComponentScore(int earned, int possible) {
    if (possible <= 0) return 0;
    return math.min(100, ((earned / possible) * 100).round());
  }
}
