import 'package:dataquest_analyst_career/models/pandas_challenge.dart';
import 'package:dataquest_analyst_career/services/pandas_simulator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guided Pandas groupby produces expected dataframe result', () {
    const challenge = PandasChallenge(
      id: 'group',
      title: 'Group',
      difficulty: 'Intermediate',
      context: '',
      datasetName: 'df',
      rows: [
        {'segment': 'A', 'revenue': 10},
        {'segment': 'A', 'revenue': 20},
        {'segment': 'B', 'revenue': 5},
      ],
      prompt: '',
      requiredFragments: ['groupby(', 'segment', 'revenue', 'sum('],
      operation: {
        'type': 'group_sum',
        'groupBy': 'segment',
        'valueColumn': 'revenue',
        'outputColumn': 'revenue',
      },
      expectedRows: [
        {'segment': 'A', 'revenue': 30},
        {'segment': 'B', 'revenue': 5},
      ],
      hints: ['1', '2', '3'],
      explanation: '',
      xp: 100,
    );

    final result = PandasSimulator.run(
      challenge,
      "df.groupby('segment')['revenue'].sum()",
    );

    expect(result.isCorrect, isTrue);
    expect(result.rows, hasLength(2));
  });

  test('guided Pandas grading rejects missing workflow fragments', () {
    const challenge = PandasChallenge(
      id: 'filter',
      title: 'Filter',
      difficulty: 'Beginner',
      context: '',
      datasetName: 'df',
      rows: [
        {'status': 'completed', 'revenue': 10},
      ],
      prompt: '',
      requiredFragments: ['status', 'completed'],
      operation: {
        'type': 'filter_equals',
        'column': 'status',
        'value': 'completed',
        'selectColumns': ['revenue'],
      },
      expectedRows: [
        {'revenue': 10},
      ],
      hints: ['1', '2', '3'],
      explanation: '',
      xp: 50,
    );

    final result = PandasSimulator.run(challenge, 'df.head()');
    expect(result.isCorrect, isFalse);
  });
}
