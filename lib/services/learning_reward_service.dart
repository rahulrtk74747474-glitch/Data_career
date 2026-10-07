class LearningRewardService {
  const LearningRewardService._();

  static const int solutionPenaltyXp = 5;

  static int earnedXp({
    required int baseXp,
    required int score,
    required bool solutionViewed,
  }) {
    final normalizedScore = score.clamp(0, 100).toInt();
    final beforePenalty = (baseXp * normalizedScore / 100).round();
    if (!solutionViewed) return beforePenalty;
    return (beforePenalty - solutionPenaltyXp)
        .clamp(0, beforePenalty)
        .toInt();
  }
}
