import 'package:dataquest_analyst_career/features/game/game_progress.dart';
import 'package:dataquest_analyst_career/models/skill_mastery.dart';
import 'package:dataquest_analyst_career/services/company_chapter_progression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bank chapter unlocks hospital only after all evidence gates pass', () {
    final progress = _progress(chapter: 2);

    final blocked = CompanyChapterProgressionService.evaluate(
      progress: progress,
      completedCurrentCompanyTickets: 4,
      skills: _skills(80),
      bossCaseScore: 74,
      interviewScore: 75,
    );
    final passed = CompanyChapterProgressionService.evaluate(
      progress: progress,
      completedCurrentCompanyTickets: 4,
      skills: _skills(80),
      bossCaseScore: 80,
      interviewScore: 82,
    );

    expect(blocked.passed, isFalse);
    expect(passed.passed, isTrue);
    expect(passed.targetChapter, 3);
  });

  test('hospital is final company chapter available in Phase 7', () {
    final review = CompanyChapterProgressionService.evaluate(
      progress: _progress(chapter: 3),
      completedCurrentCompanyTickets: 7,
      skills: _skills(90),
      bossCaseScore: 100,
      interviewScore: 100,
    );

    expect(review.finalAvailableChapter, isTrue);
    expect(review.passed, isFalse);
    expect(review.targetChapter, 3);
  });

  test('legacy save without companyChapter derives bank at Lead level', () {
    final progress = GameProgress.fromJson({
      'xp': 1600,
      'careerLevel': 4,
      'completedTaskIds': <String>[],
      'completedDailyDates': <String>[],
    });

    expect(progress.companyKey, 'bank');
    expect(progress.resolvedCompanyChapter, 2);
    expect(progress.toJson()['companyChapter'], 2);
  });
}

GameProgress _progress({required int chapter}) {
  return GameProgress(
    xp: 2400,
    streak: 0,
    completedTaskIds: const {},
    revenueIndex: 100,
    churnRate: 8,
    costIndex: 100,
    satisfaction: 70,
    careerLevel: 5,
    dailyStreak: 0,
    lastDailyDate: null,
    completedDailyDates: const {},
    companyChapter: chapter,
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
      'python',
    ])
      SkillMastery(
        skillKey: key,
        mastery: mastery,
        attempts: 3,
        correct: 3,
        nextReviewAt: null,
      ),
  ];
}
