import 'package:dataquest_analyst_career/models/interview.dart';
import 'package:dataquest_analyst_career/services/interview_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('choice scoring is exact', () {
    const question = InterviewQuestion(
      id: 'q1',
      context: '',
      prompt: '',
      answerType: 'choice',
      options: ['A', 'B'],
      expectedAnswer: 'A',
      expectedRows: [],
      criteria: [],
      explanation: '',
    );

    expect(
      InterviewScoringService.scoreChoice(question, 'A').score,
      100,
    );
    expect(
      InterviewScoringService.scoreChoice(question, 'B').score,
      0,
    );
  });

  test('rubric scoring gives credit criterion by criterion', () {
    const question = InterviewQuestion(
      id: 'q2',
      context: '',
      prompt: '',
      answerType: 'rubric',
      options: [],
      expectedAnswer: '',
      expectedRows: [],
      criteria: [
        InterviewCriterion(
          label: 'Validate data',
          weight: 40,
          keywords: ['validate', 'quality'],
        ),
        InterviewCriterion(
          label: 'Recommend action',
          weight: 60,
          keywords: ['recommend', 'test'],
        ),
      ],
      explanation: '',
    );

    final score = InterviewScoringService.scoreRubric(
      question,
      'I would validate data quality first.',
    );

    expect(score.score, 40);
    expect(score.feedback, contains('Validate data'));
    expect(score.feedback, contains('Recommend action'));
  });
}
