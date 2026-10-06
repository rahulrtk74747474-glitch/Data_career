import 'package:dataquest_analyst_career/models/evidence_attempt.dart';
import 'package:dataquest_analyst_career/models/portfolio_snapshot.dart';
import 'package:dataquest_analyst_career/models/task_performance.dart';
import 'package:dataquest_analyst_career/services/career_artifact_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resume bullets stay grounded in recorded synthetic evidence', () {
    final snapshot = PortfolioSnapshot(
      taskPerformances: [
        TaskPerformance(
          taskId: 'sql-task',
          title: 'Route SLA',
          skillKey: 'sql',
          difficulty: 'Advanced',
          bestScore: 92,
          attempts: 2,
          lastCompletedAt: DateTime.utc(2026, 10, 6),
        ),
      ],
      bossCases: const [],
      attempts: [
        EvidenceAttempt(
          attemptId: 1,
          sourceType: 'capstone',
          sourceId: 'final',
          title: 'Final Capstone',
          skillKey: 'business',
          score: 88,
          mode: 'graduation_capstone',
          companyKey: 'cross_company',
          completedAt: DateTime.utc(2026, 10, 6),
        ),
      ],
    );

    final bullets = CareerArtifactService.buildResumeBullets(snapshot);

    expect(bullets.first.text, contains('synthetic'));
    expect(bullets.first.text, contains('88/100'));
    expect(
      bullets.any((item) => item.text.contains('92/100')),
      isTrue,
    );
  });

  test('project cards preserve best score and attempt count', () {
    final attempts = [
      EvidenceAttempt(
        attemptId: 1,
        sourceType: 'boss_case',
        sourceId: 'bank-case',
        title: 'Bank Review',
        skillKey: 'business',
        score: 70,
        mode: 'boss_case',
        companyKey: 'bank',
        completedAt: DateTime.utc(2026, 10, 5),
      ),
      EvidenceAttempt(
        attemptId: 2,
        sourceType: 'boss_case',
        sourceId: 'bank-case',
        title: 'Bank Review',
        skillKey: 'business',
        score: 90,
        mode: 'boss_case',
        companyKey: 'bank',
        completedAt: DateTime.utc(2026, 10, 6),
      ),
    ];

    final cards = CareerArtifactService.buildProjectCards(
      PortfolioSnapshot(
        taskPerformances: const [],
        bossCases: const [],
        attempts: attempts,
      ),
    );

    expect(cards, hasLength(1));
    expect(cards.single.score, 90);
    expect(cards.single.attempts, 2);
    expect(cards.single.company, 'NorthStar Bank Analytics');
  });
}
