import '../models/job_ready_v15.dart';
import 'manager_explanation_service.dart';

class FlagshipWorkdayScoringService {
  const FlagshipWorkdayScoringService._();

  static int issueScore(FlagshipWorkday item, Set<String> selected) {
    if (selected.isEmpty) return 0;
    final correct = item.correctIssues.toSet();
    final hits = selected.intersection(correct).length;
    final extras = selected.difference(correct).length;
    final raw = hits / correct.length * 100 - extras * 20;
    return raw.round().clamp(0, 100).toInt();
  }

  static int toolScore(FlagshipWorkday item, String tool) =>
      item.toolScores[tool] ?? 0;

  static int tokenAnalysisScore(
    FlagshipWorkday item,
    String tool,
    String answer,
  ) {
    final rules = item.tokenRules[tool] ?? const <String>[];
    if (rules.isEmpty || answer.trim().isEmpty) return 0;
    final normalized = answer.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final hits = rules.where(
      (token) => normalized.contains(token.toLowerCase()),
    ).length;
    return (hits / rules.length * 100).round().clamp(0, 100).toInt();
  }

  static int managerScore(FlagshipWorkday item, String text) =>
      ManagerExplanationService.score(
        text: text,
        evidenceTerms: item.evidenceTerms,
        impactTerms: item.impactTerms,
        uncertaintyTerms: item.uncertaintyTerms,
        recommendationTerms: item.recommendationTerms,
      ).total;

  static int total({
    required int issue,
    required int tool,
    required int analysis,
    required int statistics,
    required int chart,
    required int manager,
  }) {
    return (issue * 0.15 +
            tool * 0.10 +
            analysis * 0.25 +
            statistics * 0.15 +
            chart * 0.10 +
            manager * 0.25)
        .round()
        .clamp(0, 100)
        .toInt();
  }
}
