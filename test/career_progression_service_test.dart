import 'package:dataquest_analyst_career/features/game/game_progress.dart';
import 'package:dataquest_analyst_career/models/skill_mastery.dart';
import 'package:dataquest_analyst_career/services/career_progression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('intern can promote only after all review criteria pass', () {
    final review = CareerProgressionService.evaluate(
      progress: _progress(
        xp: 200,
        level: 0,
        completed: 3,
      ),
      skills: _skills(60),
    );

    expect(review.targetLevel, 1);
    expect(review.passed, isTrue);
  });

  test('promotion to Analyst requires Boss Case evidence', () {
    final progress = _progress(
      xp: 500,
      level: 1,
      completed: 6,
    );

    final blocked = CareerProgressionService.evaluate(
      progress: progress,
      skills: _skills(65),
      bossCaseScore: 69,
    );
    final passed = CareerProgressionService.evaluate(
      progress: progress,
      skills: _skills(65),
      bossCaseScore: 75,
    );

    expect(blocked.passed, isFalse);
    expect(passed.passed, isTrue);
  });

  test('Data Analyst level unlocks SaaS company', () {
    final progress = _progress(
      xp: 500,
      level: 2,
      completed: 6,
    );

    expect(progress.companyKey, 'saas');
    expect(progress.companyName, 'SaaS Growth Co.');
  });
}

GameProgress _progress({
  required int xp,
  required int level,
  required int completed,
}) {
  return GameProgress(
    xp: xp,
    streak: 0,
    completedTaskIds: {
      for (var index = 0; index < completed; index++) 'task-$index',
    },
    revenueIndex: 100,
    churnRate: 8,
    costIndex: 100,
    satisfaction: 70,
    careerLevel: level,
    dailyStreak: 0,
    lastDailyDate: null,
    completedDailyDates: const {},
  );
}

List<SkillMastery> _skills(double mastery) {
  return [
    for (final key in const [
      'spreadsheets',
      'sql',
      'cleaning',
      'statistics',
      'business',
    ])
      SkillMastery(
        skillKey: key,
        mastery: mastery,
        attempts: 2,
        correct: 2,
        nextReviewAt: null,
      ),
  ];
}
