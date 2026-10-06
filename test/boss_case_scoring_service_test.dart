import 'package:dataquest_analyst_career/models/boss_case.dart';
import 'package:dataquest_analyst_career/services/boss_case_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const definition = BossCaseDefinition(
    id: 'boss',
    title: 'Boss',
    company: 'Co',
    context: '',
    datasetName: '',
    cleaningPrompt: '',
    cleaningOptions: ['A', 'B', 'X'],
    cleaningExpectedSelections: ['A', 'B'],
    sqlPrompt: '',
    sqlExpectedRows: [
      {'segment': 'Enterprise', 'total': 8000},
    ],
    kpiPrompt: '',
    kpiExpected: 59.7,
    kpiTolerance: 0.1,
    chartPrompt: '',
    chartOptions: ['Bar', 'Pie'],
    chartExpected: 'Bar',
    recommendationPrompt: '',
    recommendationOptions: ['Good', 'Bad'],
    recommendationExpected: 'Good',
    rubric: {
      'cleaning': 20,
      'sql': 30,
      'kpi': 20,
      'chart': 10,
      'recommendation': 20,
    },
  );

  test('perfect boss case receives 100', () {
    final score = BossCaseScoringService.score(
      definition: definition,
      cleaningSelections: {'A', 'B'},
      sqlRows: const [
        {'segment': 'Enterprise', 'total': 8000},
      ],
      kpiAnswer: '59.7%',
      chartAnswer: 'Bar',
      recommendationAnswer: 'Good',
    );

    expect(score.total, 100);
  });

  test('rubric removes only the missed component weight', () {
    final score = BossCaseScoringService.score(
      definition: definition,
      cleaningSelections: {'A', 'B'},
      sqlRows: const [
        {'segment': 'Enterprise', 'total': 8000},
      ],
      kpiAnswer: '59.7',
      chartAnswer: 'Pie',
      recommendationAnswer: 'Good',
    );

    expect(score.total, 90);
    expect(score.chart, 0);
  });
}
