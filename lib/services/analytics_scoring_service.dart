import '../models/analytics_challenge.dart';
import 'insight_scoring_service.dart';

class AnalyticsScore {
  const AnalyticsScore({
    required this.total,
    required this.technical,
    required this.insight,
    required this.feedback,
  });

  final int total;
  final int technical;
  final InsightRubricScore insight;
  final List<String> feedback;
}

class AnalyticsScoringService {
  const AnalyticsScoringService._();

  static AnalyticsScore score({
    required AnalyticsChallenge challenge,
    required String answer,
    required String chart,
    required Set<String> kpis,
    required String insightText,
  }) {
    final insight = InsightScoringService.score(
      text: insightText,
      evidenceTerms: challenge.evidenceTerms,
      recommendationTerms: challenge.recommendationTerms,
      impactTerms: challenge.impactTerms,
    );

    final feedback = <String>[];
    int technical;

    if (challenge.isDashboard) {
      final chartCorrect = chart == challenge.expectedChart;
      final kpiCorrect = _sameSet(
        kpis,
        challenge.expectedKpis.toSet(),
      );
      technical = (chartCorrect ? 25 : 0) + (kpiCorrect ? 25 : 0);
      if (!chartCorrect) {
        feedback.add('Chart choice does not match the decision question.');
      }
      if (!kpiCorrect) {
        feedback.add('KPI set is incomplete or includes distracting metrics.');
      }
    } else {
      technical = answer == challenge.expectedAnswer ? 50 : 0;
      if (technical == 0) {
        feedback.add('Re-check the statistical interpretation.');
      }
    }

    final insightScaled = (insight.total * 0.5).round();
    final total = (technical + insightScaled).clamp(0, 100).toInt();
    feedback.addAll(insight.feedback);

    return AnalyticsScore(
      total: total,
      technical: technical,
      insight: insight,
      feedback: feedback,
    );
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
