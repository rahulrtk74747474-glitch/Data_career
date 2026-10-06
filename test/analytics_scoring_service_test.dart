import 'package:dataquest_analyst_career/models/analytics_challenge.dart';
import 'package:dataquest_analyst_career/services/analytics_scoring_service.dart';
import 'package:dataquest_analyst_career/services/insight_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('written insight receives full rubric when all elements are present', () {
    final score = InsightScoringService.score(
      text:
          'Revenue increased 12% while orders rose 4%, so investigate average order value and test whether the mix change can protect margin and growth next month.',
      evidenceTerms: const ['revenue', 'orders'],
      recommendationTerms: const ['investigate', 'test'],
      impactTerms: const ['margin', 'growth'],
    );

    expect(score.total, 100);
    expect(score.evidence, 30);
  });

  test('dashboard technical choice and insight combine to 100', () {
    const challenge = AnalyticsChallenge(
      id: 'dash',
      title: 'Dashboard',
      mode: 'dashboard',
      skillKey: 'business',
      difficulty: 'Intermediate',
      companyKey: 'ecommerce',
      context: '',
      prompt: '',
      options: [],
      expectedAnswer: '',
      chartOptions: ['Line', 'Pie'],
      expectedChart: 'Line',
      kpiOptions: ['Revenue', 'Orders', 'Headcount'],
      expectedKpis: ['Revenue', 'Orders'],
      insightPrompt: '',
      evidenceTerms: ['revenue', 'orders'],
      recommendationTerms: ['monitor'],
      impactTerms: ['growth'],
      hints: ['a', 'b', 'c'],
      explanation: '',
      xp: 100,
    );

    final score = AnalyticsScoringService.score(
      challenge: challenge,
      answer: '',
      chart: 'Line',
      kpis: {'Revenue', 'Orders'},
      insightText:
          'Revenue grew 12% as orders increased 4%; monitor order value next month to confirm the growth is sustainable.',
    );

    expect(score.technical, 50);
    expect(score.total, 100);
  });

  test('wrong statistical interpretation cannot pass on writing alone', () {
    const challenge = AnalyticsChallenge(
      id: 'stats',
      title: 'Stats',
      mode: 'statistics',
      skillKey: 'statistics',
      difficulty: 'Advanced',
      companyKey: 'saas',
      context: '',
      prompt: '',
      options: ['Correct', 'Wrong'],
      expectedAnswer: 'Correct',
      chartOptions: [],
      expectedChart: '',
      kpiOptions: [],
      expectedKpis: [],
      insightPrompt: '',
      evidenceTerms: ['retention'],
      recommendationTerms: ['test'],
      impactTerms: ['churn'],
      hints: ['a', 'b', 'c'],
      explanation: '',
      xp: 100,
    );

    final score = AnalyticsScoringService.score(
      challenge: challenge,
      answer: 'Wrong',
      chart: '',
      kpis: const {},
      insightText:
          'Retention moved 10%, so test the pattern again before changing churn policy or customer strategy.',
    );

    expect(score.technical, 0);
    expect(score.total, lessThanOrEqualTo(50));
  });
}
