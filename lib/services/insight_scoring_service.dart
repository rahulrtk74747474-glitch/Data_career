class InsightRubricScore {
  const InsightRubricScore({
    required this.clarity,
    required this.evidence,
    required this.recommendation,
    required this.businessImpact,
    required this.feedback,
  });

  final int clarity;
  final int evidence;
  final int recommendation;
  final int businessImpact;
  final List<String> feedback;

  int get total =>
      clarity + evidence + recommendation + businessImpact;
}

class InsightScoringService {
  const InsightScoringService._();

  static InsightRubricScore score({
    required String text,
    required List<String> evidenceTerms,
    required List<String> recommendationTerms,
    required List<String> impactTerms,
  }) {
    final normalized = text.trim().toLowerCase();
    final words = normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final feedback = <String>[];

    final clarity = _clarity(words.length, normalized, feedback);
    final evidence = _evidence(
      normalized,
      evidenceTerms,
      feedback,
    );
    final recommendation = _keywordScore(
      normalized,
      recommendationTerms,
      25,
      'Add a concrete next action or recommendation.',
      feedback,
    );
    final impact = _keywordScore(
      normalized,
      impactTerms,
      20,
      'Connect the finding to a business or operational impact.',
      feedback,
    );

    if (feedback.isEmpty) {
      feedback.add(
        'Strong insight: clear, evidence-led, actionable and tied to impact.',
      );
    }

    return InsightRubricScore(
      clarity: clarity,
      evidence: evidence,
      recommendation: recommendation,
      businessImpact: impact,
      feedback: feedback,
    );
  }

  static int _clarity(
    int wordCount,
    String normalized,
    List<String> feedback,
  ) {
    if (wordCount >= 12 && wordCount <= 90) {
      return 25;
    }
    if (wordCount >= 8 && wordCount <= 120) {
      feedback.add('Tighten the insight to roughly 12–90 words.');
      return 18;
    }
    feedback.add(
      wordCount < 8
          ? 'Explain the finding in a complete decision-ready sentence.'
          : 'Shorten the insight so the main point is easy to scan.',
    );
    return 10;
  }

  static int _evidence(
    String normalized,
    List<String> evidenceTerms,
    List<String> feedback,
  ) {
    final hasTerm = _containsAny(normalized, evidenceTerms);
    final hasNumber = RegExp(r'\d').hasMatch(normalized);
    if (hasTerm && hasNumber) return 30;
    if (hasTerm || hasNumber) {
      feedback.add(
        'Strengthen the evidence by naming the metric and quantifying it.',
      );
      return 18;
    }
    feedback.add(
      'State the supporting metric, comparison or number before recommending action.',
    );
    return 6;
  }

  static int _keywordScore(
    String normalized,
    List<String> terms,
    int maxScore,
    String missingFeedback,
    List<String> feedback,
  ) {
    if (_containsAny(normalized, terms)) return maxScore;
    feedback.add(missingFeedback);
    return (maxScore * 0.35).round();
  }

  static bool _containsAny(String text, List<String> terms) {
    return terms.any(
      (term) => text.contains(term.trim().toLowerCase()),
    );
  }
}
