import 'package:dataquest_analyst_career/models/capstone.dart';
import 'package:dataquest_analyst_career/services/capstone_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const definition = CapstoneDefinition(
    id: 'capstone',
    title: 'Capstone',
    context: '',
    datasetName: '',
    cleaningPrompt: '',
    cleaningOptions: ['A', 'B', 'C'],
    cleaningExpectedSelections: ['A', 'B'],
    sqlPrompt: '',
    sqlExpectedRows: [
      {'company': 'A', 'change': 5.0},
    ],
    statisticsPrompt: '',
    statisticsOptions: ['Good', 'Bad'],
    statisticsExpected: 'Good',
    kpiPrompt: '',
    kpiExpected: 87.6,
    kpiTolerance: 0.1,
    dashboardPrompt: '',
    dashboardOptions: ['Chart', 'Other'],
    dashboardExpected: 'Chart',
    recommendationPrompt: '',
    recommendationOptions: ['Act', 'Other'],
    recommendationExpected: 'Act',
    rubric: {
      'cleaning': 15,
      'sql': 25,
      'statistics': 15,
      'kpi': 15,
      'dashboard': 10,
      'recommendation': 20,
    },
  );

  test('perfect capstone receives 100', () {
    final score = CapstoneScoringService.score(
      definition: definition,
      cleaningSelections: {'A', 'B'},
      sqlRows: const [
        {'company': 'A', 'change': 5},
      ],
      statisticsAnswer: 'Good',
      kpiAnswer: '87.6%',
      dashboardAnswer: 'Chart',
      recommendationAnswer: 'Act',
    );

    expect(score.total, 100);
  });

  test('missing statistics removes only statistics weight', () {
    final score = CapstoneScoringService.score(
      definition: definition,
      cleaningSelections: {'A', 'B'},
      sqlRows: const [
        {'company': 'A', 'change': 5},
      ],
      statisticsAnswer: 'Bad',
      kpiAnswer: '87.6',
      dashboardAnswer: 'Chart',
      recommendationAnswer: 'Act',
    );

    expect(score.total, 85);
    expect(score.statistics, 0);
  });
}
