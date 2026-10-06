import '../features/game/game_progress.dart';
import '../models/evidence_attempt.dart';
import '../models/portfolio_snapshot.dart';

class ResumeBulletSuggestion {
  const ResumeBulletSuggestion({
    required this.id,
    required this.text,
  });

  final String id;
  final String text;
}

class PortfolioProjectCard {
  const PortfolioProjectCard({
    required this.id,
    required this.title,
    required this.company,
    required this.score,
    required this.skills,
    required this.attempts,
  });

  final String id;
  final String title;
  final String company;
  final int score;
  final List<String> skills;
  final int attempts;
}

class CareerArtifactService {
  const CareerArtifactService._();

  static List<ResumeBulletSuggestion> buildResumeBullets(
    PortfolioSnapshot snapshot,
  ) {
    final suggestions = <ResumeBulletSuggestion>[];
    final bestEvidence = _bestEvidenceBySource(snapshot.attempts);

    final capstones = bestEvidence.values
        .where((item) => item.sourceType == 'capstone')
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    if (capstones.isNotEmpty) {
      final item = capstones.first;
      suggestions.add(
        ResumeBulletSuggestion(
          id: 'capstone:${item.sourceId}',
          text:
              'Completed a synthetic cross-company analytics capstone spanning data quality, SQL, statistics, KPI/dashboard reasoning and executive recommendation, scoring ${item.score}/100.',
        ),
      );
    }

    final bossCases = bestEvidence.values
        .where((item) => item.sourceType == 'boss_case')
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    for (final item in bossCases.take(3)) {
      suggestions.add(
        ResumeBulletSuggestion(
          id: 'boss:${item.sourceId}',
          text:
              'Completed the synthetic ${item.title} case for ${_companyName(item.companyKey)}, integrating SQL, KPI interpretation and decision communication with a ${item.score}/100 score.',
        ),
      );
    }

    for (final item in snapshot.taskPerformances.take(3)) {
      suggestions.add(
        ResumeBulletSuggestion(
          id: 'task:${item.taskId}',
          text:
              'Practiced ${item.skillKey} through the “${item.title}” analyst exercise, achieving a best score of ${item.bestScore}/100 across ${item.attempts} attempt${item.attempts == 1 ? '' : 's'}.',
        ),
      );
    }

    return suggestions;
  }

  static List<PortfolioProjectCard> buildProjectCards(
    PortfolioSnapshot snapshot,
  ) {
    final best = _bestEvidenceBySource(snapshot.attempts);
    final attemptsBySource = <String, int>{};

    for (final item in snapshot.attempts) {
      if (item.sourceType != 'boss_case' && item.sourceType != 'capstone') {
        continue;
      }
      final key = '${item.sourceType}:${item.sourceId}';
      attemptsBySource[key] = (attemptsBySource[key] ?? 0) + 1;
    }

    final items = best.values
        .where(
          (item) =>
              item.sourceType == 'boss_case' ||
              item.sourceType == 'capstone',
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return [
      for (final item in items)
        PortfolioProjectCard(
          id: '${item.sourceType}:${item.sourceId}',
          title: item.title,
          company: _companyName(item.companyKey),
          score: item.score,
          skills: item.sourceType == 'capstone'
              ? const [
                  'Cleaning',
                  'SQL',
                  'Statistics',
                  'KPI',
                  'Dashboard',
                  'Communication',
                ]
              : const [
                  'Cleaning',
                  'SQL',
                  'KPI',
                  'Visualization',
                  'Communication',
                ],
          attempts:
              attemptsBySource['${item.sourceType}:${item.sourceId}'] ?? 1,
        ),
    ];
  }

  static Map<String, EvidenceAttempt> _bestEvidenceBySource(
    List<EvidenceAttempt> attempts,
  ) {
    final best = <String, EvidenceAttempt>{};
    for (final item in attempts) {
      final key = '${item.sourceType}:${item.sourceId}';
      final existing = best[key];
      if (existing == null || item.score > existing.score) {
        best[key] = item;
      }
    }
    return best;
  }

  static String _companyName(String key) {
    final index = GameProgress.companyKeys.indexOf(key);
    if (index >= 0) return GameProgress.companyNames[index];
    if (key == 'cross_company') return 'Cross-company portfolio';
    return key;
  }
}
