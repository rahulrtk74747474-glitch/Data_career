import 'package:dataquest_analyst_career/models/evidence_attempt.dart';
import 'package:dataquest_analyst_career/models/portfolio_snapshot.dart';
import 'package:dataquest_analyst_career/models/skill_mastery.dart';
import 'package:dataquest_analyst_career/services/portfolio_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HTML export includes print guidance and immutable history', () {
    final snapshot = PortfolioSnapshot(
      taskPerformances: const [],
      bossCases: const [],
      attempts: [
        EvidenceAttempt(
          attemptId: 1,
          sourceType: 'interview',
          sourceId: 'bank_analytics',
          title: 'Bank Analytics Interview',
          skillKey: 'business',
          score: 82,
          mode: 'timed',
          companyKey: 'bank',
          completedAt: DateTime.utc(2026, 10, 6, 8),
        ),
      ],
    );

    final html = PortfolioExportService.buildHtml(
      snapshot: snapshot,
      role: 'Lead Analyst',
      companyName: 'NorthStar Bank Analytics',
      xp: 1600,
      skills: const [
        SkillMastery(
          skillKey: 'sql',
          mastery: 80,
          attempts: 4,
          correct: 3,
          nextReviewAt: null,
        ),
      ],
      generatedAt: DateTime.utc(2026, 10, 6, 9),
    );

    expect(html, contains('DataQuest Analyst Portfolio'));
    expect(html, contains('NorthStar Bank Analytics'));
    expect(html, contains('Print → Save as PDF'));
    expect(html, contains('Immutable attempt history'));
    expect(html, contains('Bank Analytics Interview'));
    expect(html, contains('@media print'));
  });
}
