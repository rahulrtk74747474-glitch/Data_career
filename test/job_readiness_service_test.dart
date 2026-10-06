import 'package:dataquest_analyst_career/features/game/game_progress.dart';
import 'package:dataquest_analyst_career/models/boss_case_result.dart';
import 'package:dataquest_analyst_career/models/capstone_result.dart';
import 'package:dataquest_analyst_career/models/evidence_attempt.dart';
import 'package:dataquest_analyst_career/models/interview_result.dart';
import 'package:dataquest_analyst_career/models/skill_mastery.dart';
import 'package:dataquest_analyst_career/services/job_readiness_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('readiness score excludes XP and uses demonstrated evidence', () {
    final lowXp = _progress(xp: 2000);
    final highXp = _progress(xp: 99999);

    final low = JobReadinessService.calculate(
      progress: lowXp,
      skills: _skills(80),
      bossCases: [_boss(80)],
      interviews: [_interview(80)],
      evidence: _evidence(80),
      capstone: _capstone(80),
    );
    final high = JobReadinessService.calculate(
      progress: highXp,
      skills: _skills(80),
      bossCases: [_boss(80)],
      interviews: [_interview(80)],
      evidence: _evidence(80),
      capstone: _capstone(80),
    );

    expect(low.totalScore, high.totalScore);
    expect(low.totalScore, greaterThanOrEqualTo(80));
  });

  test('weak SQL creates targeted remediation', () {
    final skills = _skills(85)
        .map(
          (skill) => skill.skillKey == 'sql'
              ? SkillMastery(
                  skillKey: 'sql',
                  mastery: 52,
                  attempts: 3,
                  correct: 1,
                  nextReviewAt: null,
                )
              : skill,
        )
        .toList();

    final report = JobReadinessService.calculate(
      progress: _progress(xp: 2500),
      skills: skills,
      bossCases: [_boss(85)],
      interviews: [_interview(85)],
      evidence: _evidence(85),
      capstone: _capstone(85),
    );

    expect(report.domain('sql')!.score, 52);
    expect(
      report.remediation.any((item) => item.startsWith('SQL:')),
      isTrue,
    );
  });
}

GameProgress _progress({required int xp}) {
  return GameProgress(
    xp: xp,
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
    companyChapter: 4,
    companyJourneyCompleted: true,
  );
}

List<SkillMastery> _skills(double score) {
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
        mastery: score,
        attempts: 3,
        correct: 3,
        nextReviewAt: null,
      ),
  ];
}

BossCaseResult _boss(int score) {
  return BossCaseResult(
    caseId: 'boss',
    completedAt: DateTime.utc(2026, 10, 6),
    totalScore: score,
    cleaningScore: 15,
    sqlScore: 25,
    kpiScore: 15,
    chartScore: 10,
    recommendationScore: 15,
  );
}

InterviewResult _interview(int score) {
  return InterviewResult(
    roundKey: 'sql',
    completedAt: DateTime.utc(2026, 10, 6),
    bestScore: score,
    latestScore: score,
    attempts: 1,
    lastMode: 'timed',
  );
}

CapstoneResult _capstone(int score) {
  return CapstoneResult(
    capstoneId: 'capstone',
    completedAt: DateTime.utc(2026, 10, 6),
    totalScore: score,
    cleaningScore: 15,
    sqlScore: 25,
    statisticsScore: 15,
    kpiScore: 10,
    dashboardScore: 5,
    recommendationScore: 10,
  );
}

List<EvidenceAttempt> _evidence(int score) {
  const companies = ['ecommerce', 'saas', 'bank', 'hospital', 'logistics'];
  return [
    for (var index = 0; index < companies.length; index++)
      EvidenceAttempt(
        attemptId: index + 1,
        sourceType: 'boss_case',
        sourceId: 'case-$index',
        title: 'Case $index',
        skillKey: 'business',
        score: score,
        mode: 'boss_case',
        companyKey: companies[index],
        completedAt: DateTime.utc(2026, 10, 6),
      ),
  ];
}
