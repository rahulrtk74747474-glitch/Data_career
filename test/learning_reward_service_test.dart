import 'package:dataquest_analyst_career/services/learning_reward_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('viewing a solution reduces earned XP by exactly five', () {
    final normal = LearningRewardService.earnedXp(
      baseXp: 100,
      score: 80,
      solutionViewed: false,
    );
    final helped = LearningRewardService.earnedXp(
      baseXp: 100,
      score: 80,
      solutionViewed: true,
    );

    expect(normal, 80);
    expect(helped, 75);
    expect(normal - helped, LearningRewardService.solutionPenaltyXp);
  });

  test('solution penalty never produces negative XP', () {
    expect(
      LearningRewardService.earnedXp(
        baseXp: 4,
        score: 100,
        solutionViewed: true,
      ),
      0,
    );
  });
}
