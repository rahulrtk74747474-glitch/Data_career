import 'package:dataquest_analyst_career/models/boss_case_result.dart';
import 'package:dataquest_analyst_career/models/portfolio_snapshot.dart';
import 'package:dataquest_analyst_career/models/skill_mastery.dart';
import 'package:dataquest_analyst_career/models/task_performance.dart';
import 'package:dataquest_analyst_career/services/portfolio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('portfolio calculations identify strongest evidence and average', () {
    final snapshot = PortfolioSnapshot(
      taskPerformances: [
        TaskPerformance(
          taskId: 'a',
          title: 'SQL Join',
          skillKey: 'sql',
          difficulty: 'Intermediate',
          bestScore: 80,
          attempts: 2,
          lastCompletedAt: DateTime.utc(2026, 10, 6),
        ),
        TaskPerformance(
          taskId: 'b',
          title: 'Pandas GroupBy',
          skillKey: 'python',
          difficulty: 'Intermediate',
          bestScore: 100,
          attempts: 1,
          lastCompletedAt: DateTime.utc(2026, 10, 6),
        ),
      ],
      bossCases: [
        BossCaseResult(
          caseId: 'boss-1',
          completedAt: DateTime.utc(2026, 10, 6),
          totalScore: 90,
          cleaningScore: 20,
          sqlScore: 30,
          kpiScore: 20,
          chartScore: 0,
          recommendationScore: 20,
        ),
      ],
    );

    expect(snapshot.evidenceCount, 3);
    expect(snapshot.averageBestScore, 90);
    expect(snapshot.strongestTask!.title, 'Pandas GroupBy');
  });

  test('portfolio summary includes role, evidence and boss score', () {
    final snapshot = PortfolioSnapshot(
      taskPerformances: [
        TaskPerformance(
          taskId: 'a',
          title: 'SQL Join',
          skillKey: 'sql',
          difficulty: 'Intermediate',
          bestScore: 95,
          attempts: 1,
          lastCompletedAt: DateTime.utc(2026, 10, 6),
        ),
      ],
      bossCases: [
        BossCaseResult(
          caseId: 'boss-1',
          completedAt: DateTime.utc(2026, 10, 6),
          totalScore: 85,
          cleaningScore: 20,
          sqlScore: 30,
          kpiScore: 20,
          chartScore: 0,
          recommendationScore: 15,
        ),
      ],
    );

    const skills = [
      SkillMastery(
        skillKey: 'sql',
        mastery: 88,
        attempts: 3,
        correct: 3,
        nextReviewAt: null,
      ),
    ];

    final summary = PortfolioService.buildSummary(
      snapshot: snapshot,
      role: 'Data Analyst',
      xp: 650,
      skills: skills,
    );

    expect(summary, contains('Role: Data Analyst'));
    expect(summary, contains('SQL Join'));
    expect(summary, contains('boss-1: 85/100'));
  });
}
