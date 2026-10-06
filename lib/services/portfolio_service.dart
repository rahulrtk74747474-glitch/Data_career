import '../models/portfolio_snapshot.dart';
import '../models/skill_mastery.dart';

class PortfolioService {
  const PortfolioService._();

  static String buildSummary({
    required PortfolioSnapshot snapshot,
    required String role,
    required int xp,
    required List<SkillMastery> skills,
  }) {
    final buffer = StringBuffer()
      ..writeln('DataQuest Analyst Portfolio')
      ..writeln('Role: $role')
      ..writeln('Career XP: $xp')
      ..writeln(
        'Evidence items: ${snapshot.evidenceCount}',
      );

    if (skills.isNotEmpty) {
      buffer.writeln('\nSkill profile:');
      final sortedSkills = [...skills]
        ..sort((a, b) => b.mastery.compareTo(a.mastery));
      for (final skill in sortedSkills) {
        buffer.writeln(
          '- ${skill.displayName}: ${skill.mastery.toStringAsFixed(0)}%',
        );
      }
    }

    if (snapshot.taskPerformances.isNotEmpty) {
      buffer.writeln('\nStrongest ticket/lab evidence:');
      for (final task in snapshot.taskPerformances.take(8)) {
        buffer.writeln(
          '- ${task.title} | ${task.skillKey} | ${task.difficulty} | best ${task.bestScore}/100 | attempts ${task.attempts}',
        );
      }
    }

    if (snapshot.bossCases.isNotEmpty) {
      buffer.writeln('\nBoss Cases:');
      for (final result in snapshot.bossCases) {
        buffer.writeln(
          '- ${result.caseId}: ${result.totalScore}/100 (Cleaning ${result.cleaningScore}, SQL ${result.sqlScore}, KPI ${result.kpiScore}, Chart ${result.chartScore}, Recommendation ${result.recommendationScore})',
        );
      }
    }

    if (snapshot.evidenceCount == 0) {
      buffer.writeln(
        '\nComplete tickets, labs, or a Boss Case to create portfolio evidence.',
      );
    }

    return buffer.toString().trim();
  }
}
