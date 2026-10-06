import 'package:dataquest_analyst_career/models/dashboard_challenge.dart';
import 'package:dataquest_analyst_career/services/dashboard_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard grader accepts only the defensible design answer', () {
    const challenge = DashboardChallenge(
      id: 'chart',
      title: 'Trend',
      difficulty: 'Beginner',
      category: 'Chart Choice',
      context: '',
      prompt: '',
      options: ['Line', 'Pie'],
      correctOption: 'Line',
      hints: ['1', '2', '3'],
      explanation: '',
    );

    expect(
      DashboardScoringService.grade(challenge, 'Line').isCorrect,
      isTrue,
    );
    expect(
      DashboardScoringService.grade(challenge, 'Pie').isCorrect,
      isFalse,
    );
  });
}
