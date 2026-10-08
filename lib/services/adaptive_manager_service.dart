import '../models/job_ready_v15.dart';
import 'manager_explanation_service.dart';

class AdaptiveCoachTurn {
  const AdaptiveCoachTurn({
    required this.score,
    required this.feedback,
    required this.nextQuestion,
    required this.strong,
  });

  final int score;
  final String feedback;
  final String nextQuestion;
  final bool strong;
}

class AdaptiveManagerService {
  const AdaptiveManagerService._();

  static AdaptiveCoachTurn respond({
    required AdaptiveCoachScenario scenario,
    required String answer,
    required int turn,
  }) {
    final score = ManagerExplanationService.score(
      text: answer,
      evidenceTerms: scenario.evidenceTerms,
      impactTerms: const [
        'revenue',
        'cost',
        'customer',
        'risk',
        'retention',
        'service',
        'capacity',
        'growth',
        'margin',
        'operations',
      ],
      uncertaintyTerms: scenario.uncertaintyTerms,
      recommendationTerms: scenario.recommendationTerms,
    );

    String next;
    if (score.evidence < 20) {
      next =
          'What concrete metric, comparison or observed result supports your claim?';
    } else if (score.uncertainty == 0) {
      next =
          'What could make this conclusion wrong? Name a confounder, bias, denominator issue or data limitation.';
    } else if (score.recommendation < 12) {
      next =
          'What specific action would you recommend next, and what would you monitor after that action?';
    } else if (score.businessImpact < 12) {
      next =
          'Why should a manager care? Connect this finding to revenue, cost, risk, customer experience or operations.';
    } else if (turn < 2) {
      next =
          'Good. Now defend your choice against a skeptical executive: why is your method better than the obvious shortcut?';
    } else {
      next =
          'Final follow-up: what metric would tell you in one week whether your recommendation worked?';
    }

    return AdaptiveCoachTurn(
      score: score.total,
      feedback: score.feedback.join(' '),
      nextQuestion: next,
      strong: score.total >= 75,
    );
  }
}
