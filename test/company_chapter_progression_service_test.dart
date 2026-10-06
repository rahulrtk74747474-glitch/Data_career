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
    expect(passed.finalAvailableChapter, isFalse);
  });

  test('hospital chapter unlocks logistics after hospital evidence', () {
    final progress = _progress(chapter: 3);

    final blocked = CompanyChapterProgressionService.evaluate(
      progress: progress,
      completedCurrentCompanyTickets: 5,
      skills: _skills(82),
      bossCaseScore: 78,
      interviewScore: 77,
    );
    final passed = CompanyChapterProgressionService.evaluate(
      progress: progress,
      completedCurrentCompanyTickets: 5,
      skills: _skills(84),
      bossCaseScore: 82,
      interviewScore: 84,
    );

    expect(blocked.passed, isFalse);
    expect(passed.passed, isTrue);
    expect(passed.targetChapter, 4);
    expect(passed.finalAvailableChapter, isFalse);
  });

  test('logistics chapter becomes final journey completion review', () {
    final review = CompanyChapterProgressionService.evaluate(
      progress: _progress(chapter: 4),
      completedCurrentCompanyTickets: 6,
      skills: _skills(88),
      bossCaseScore: 90,
      interviewScore: 90,
    );

    expect(review.finalAvailableChapter, isTrue);
    expect(review.isJourneyCompletionReview, isTrue);
    expect(review.targetChapter, 4);
    expect(review.passed, isTrue);
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
    expect(progress.companyJourneyCompleted, isFalse);
  });

  test('journey completion is separately persisted from role and chapter', () {
    final progress = GameProgress.fromJson({
      'xp': 2600,
      'careerLevel': 5,
      'companyChapter': 4,
      'companyJourneyCompleted': true,
      'completedTaskIds': <String>[],
      'completedDailyDates': <String>[],
    });

    expect(progress.role, 'Head of Analytics');
    expect(progress.companyKey, 'logistics');
    expect(progress.companyJourneyCompleted, isTrue);
  });
}

GameProgress _progress({required int chapter}) {
  return GameProgress(
    xp: 2600,
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
