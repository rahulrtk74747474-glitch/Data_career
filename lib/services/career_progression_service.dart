import '../features/game/game_progress.dart';
import '../models/skill_mastery.dart';

class PromotionCriterion {
  const PromotionCriterion({
    required this.label,
    required this.met,
    required this.detail,
  });

  final String label;
  final bool met;
  final String detail;
}

class PromotionReview {
  const PromotionReview({
    required this.currentLevel,
    required this.targetLevel,
    required this.criteria,
  });

  final int currentLevel;
  final int targetLevel;
  final List<PromotionCriterion> criteria;

  bool get isTopRole => currentLevel >= 5;
  bool get passed => !isTopRole && criteria.every((item) => item.met);
}

class CareerProgressionService {
  const CareerProgressionService._();

  static const _completedRequirements = [3, 6, 9, 10, 14];
  static const _masteryRequirements = [40.0, 55.0, 65.0, 72.0, 80.0];
  static const _interviewRequirements = [0, 0, 0, 65, 75];

  static PromotionReview evaluate({
    required GameProgress progress,
    required List<SkillMastery> skills,
    int? bossCaseScore,
    int? bestInterviewScore,
  }) {
    if (progress.isTopRole) {
      return PromotionReview(
        currentLevel: progress.careerLevel,
        targetLevel: progress.careerLevel,
        criteria: const [],
      );
    }

    final level = progress.careerLevel;
    final target = level + 1;
    final xpRequired = GameProgress.xpThresholds[level];
    final completedRequired = _completedRequirements[level];
    final masteryRequired = _masteryRequirements[level];
    final attempted = skills.where((skill) => skill.attempts > 0).toList();
    final averageMastery = attempted.isEmpty
        ? 0.0
        : attempted.fold<double>(
              0,
              (sum, skill) => sum + skill.mastery,
            ) /
            attempted.length;

    final criteria = <PromotionCriterion>[
      PromotionCriterion(
        label: 'Career XP',
        met: progress.xp >= xpRequired,
        detail: '${progress.xp} / $xpRequired XP',
      ),
      PromotionCriterion(
        label: 'Completed career tickets',
        met: progress.completedTaskIds.length >= completedRequired,
        detail:
            '${progress.completedTaskIds.length} / $completedRequired tickets',
      ),
      PromotionCriterion(
        label: 'Average attempted-skill mastery',
        met: averageMastery >= masteryRequired,
        detail:
            '${averageMastery.toStringAsFixed(0)}% / ${masteryRequired.toStringAsFixed(0)}%',
      ),
    ];

    if (target >= 2) {
      const requiredBossScore = 70;
      final bossScore = bossCaseScore ?? 0;
      criteria.add(
        PromotionCriterion(
          label: 'Boss Case',
          met: bossScore >= requiredBossScore,
          detail: '$bossScore / $requiredBossScore',
        ),
      );
    }

    final interviewRequired = _interviewRequirements[level];
    if (interviewRequired > 0) {
      final interviewScore = bestInterviewScore ?? 0;
      criteria.add(
        PromotionCriterion(
          label: 'Interview readiness',
          met: interviewScore >= interviewRequired,
          detail: '$interviewScore / $interviewRequired',
        ),
      );
    }

    return PromotionReview(
      currentLevel: level,
      targetLevel: target,
      criteria: criteria,
    );
  }
}
