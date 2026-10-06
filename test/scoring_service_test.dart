import 'package:dataquest_analyst_career/models/analyst_task.dart';
import 'package:dataquest_analyst_career/services/scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AnalystTask task({
    required String answerType,
    String expectedAnswer = '',
    List<String> requiredTokens = const [],
  }) {
    return AnalystTask(
      id: 'test',
      title: 'Test',
      department: 'Sales',
      skill: 'Test',
      context: 'Context',
      goal: 'Goal',
      deliverable: 'Deliverable',
      answerType: answerType,
      prompt: 'Prompt',
      expectedAnswer: expectedAnswer,
      requiredTokens: requiredTokens,
      hints: const ['h1', 'h2', 'h3'],
      explanation: 'Explanation',
      xp: 100,
      datasetName: '',
      rows: const [],
      options: const [],
    );
  }

  test('formula grader ignores spaces and absolute reference symbols', () {
    final result = ScoringService.grade(
      task(
        answerType: 'formula',
        expectedAnswer: '=B2*C2*(1-D2)',
      ),
      '= B2 * C2 * (1 - $D2)',
    );

    expect(result.isCorrect, isTrue);
  });

  test('SQL token grader accepts required SQL logic', () {
    final result = ScoringService.grade(
      task(
        answerType: 'sql_tokens',
        requiredTokens: const [
          'select',
          'channel',
          'sum(conversions)',
          'from campaign_performance',
          'group by channel',
        ],
      ),
      '''
      SELECT channel, SUM(conversions)
      FROM campaign_performance
      GROUP BY channel;
      ''',
    );

    expect(result.isCorrect, isTrue);
  });

  test('SQL token grader rejects incomplete aggregation', () {
    final result = ScoringService.grade(
      task(
        answerType: 'sql_tokens',
        requiredTokens: const [
          'sum(conversions)',
          'group by channel',
        ],
      ),
      'SELECT channel FROM campaign_performance;',
    );

    expect(result.isCorrect, isFalse);
  });
}
