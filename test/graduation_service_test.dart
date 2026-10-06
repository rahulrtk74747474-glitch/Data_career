import 'package:dataquest_analyst_career/features/game/game_progress.dart';
import 'package:dataquest_analyst_career/models/capstone_result.dart';
import 'package:dataquest_analyst_career/models/interview_result.dart';
import 'package:dataquest_analyst_career/models/job_readiness.dart';
import 'package:dataquest_analyst_career/services/graduation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all evidence gates unlock graduation', () {
    final eligibility = GraduationService.evaluate(
      progress: _progress(completed: true),
      readiness: _readiness(total: 84, domainScore: 78),
      capstone: _capstone(86),
      gauntlet: _gauntlet(82),
    );

    expect(eligibility.eligible, isTrue);
  });

  test('critical skill gap blocks certificate despite high total', () {
    final eligibility = GraduationService.evaluate(
      progress: _progress(completed: true),
      readiness: _readiness(total: 90, domainScore: 60),
      capstone: _capstone(90),
      gauntlet: _gauntlet(90),
    );

    expect(eligibility.eligible, isFalse);
    expect(
      eligibility.criteria
          .singleWhere((item) => item.label == 'No critical skill gap')
          .met,
      isFalse,
    );
  });
}

GameProgress _progress({required bool completed}) {
  return GameProgress(
    xp: 2500,
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
    companyJourneyCompleted: completed,
  );
}

JobReadinessReport _readiness({
  required int total,
  required double domainScore,
}) {
  final domains = [
    for (final key in const [
      'sql',
      'data_prep',
      'statistics',
      'python',
      'business',
      'interviews',
    ])
      ReadinessDomain(
        key: key,
        label: key,
        score: domainScore,
        recommendation: '',
      ),
  ];

  return JobReadinessReport(
    totalScore: total,
    domains: domains,
    skillFoundationScore: domainScore,
    interviewScore: 80,
    bossCaseScore: 80,
    evidenceScore: 80,
    completionScore: 100,
    capstoneScore: 80,
    remediation: const [],
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
    kpiScore: 15,
    dashboardScore: 10,
    recommendationScore: 20,
  );
}

InterviewResult _gauntlet(int score) {
  return InterviewResult(
    roundKey: 'job_readiness_gauntlet',
    completedAt: DateTime.utc(2026, 10, 6),
    bestScore: score,
    latestScore: score,
    attempts: 1,
    lastMode: 'timed',
  );
}
