class ManagerExplanationScore {
  const ManagerExplanationScore({
    required this.evidence,
    required this.clarity,
    required this.businessImpact,
    required this.uncertainty,
    required this.recommendation,
    required this.feedback,
  });

  final int evidence;
  final int clarity;
  final int businessImpact;
  final int uncertainty;
  final int recommendation;
  final List<String> feedback;

  int get total =>
      evidence + clarity + businessImpact + uncertainty + recommendation;
}

class ManagerExplanationService {
  const ManagerExplanationService._();

  static ManagerExplanationScore score({
    required String text,
    List<String> evidenceTerms = const [],
    List<String> impactTerms = const [],
    List<String> uncertaintyTerms = const [],
    List<String> recommendationTerms = const [],
  }) {
    final normalized = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final words = normalized.isEmpty ? <String>[] : normalized.split(' ');
    final sentences = text
        .split(RegExp(r'[.!?]+'))
        .where((item) => item.trim().isNotEmpty)
        .length;

    final evidencePool = evidenceTerms.isEmpty
        ? const [
            'data', 'result', 'evidence', 'rate', 'revenue', 'cost',
            'retention', 'wait', 'segment', 'average', 'median', 'percent',
          ]
        : evidenceTerms;
    final impactPool = impactTerms.isEmpty
        ? const [
            'revenue', 'cost', 'profit', 'customer', 'risk', 'retention',
            'service', 'capacity', 'growth', 'margin', 'operations',
          ]
        : impactTerms;
    final uncertaintyPool = uncertaintyTerms.isEmpty
        ? const [
            'may', 'might', 'could', 'uncertain', 'association',
            'does not prove', 'not prove', 'sample', 'mix', 'confound',
            'limitation',
          ]
        : uncertaintyTerms;
    final recommendationPool = recommendationTerms.isEmpty
        ? const [
            'recommend', 'should', 'next', 'investigate', 'test', 'monitor',
            'compare', 'validate', 'segment',
          ]
        : recommendationTerms;

    final evidenceHits = _hits(normalized, evidencePool) +
        (RegExp(r'\d').hasMatch(normalized) ? 1 : 0);
    final impactHits = _hits(normalized, impactPool);
    final uncertaintyHits = _hits(normalized, uncertaintyPool);
    final recommendationHits = _hits(normalized, recommendationPool);

    final evidence = evidenceHits >= 3
        ? 25
        : evidenceHits == 2
            ? 20
            : evidenceHits == 1
                ? 12
                : 0;
    final clarity = words.length >= 24 && words.length <= 130 && sentences >= 2
        ? 20
        : words.length >= 14 && sentences >= 1
            ? 12
            : 5;
    final businessImpact = impactHits >= 2
        ? 20
        : impactHits == 1
            ? 12
            : 0;
    final uncertainty = uncertaintyHits >= 1 ? 15 : 0;
    final recommendation = recommendationHits >= 2
        ? 20
        : recommendationHits == 1
            ? 12
            : 0;

    final feedback = <String>[];
    if (evidence < 20) {
      feedback.add('Cite a concrete metric, result or segment as evidence.');
    }
    if (clarity < 20) {
      feedback.add('Use 2–4 concise sentences: finding → evidence → action.');
    }
    if (businessImpact < 12) {
      feedback.add('Explain why the finding matters to the business or operation.');
    }
    if (uncertainty == 0) {
      feedback.add('State a limitation, uncertainty or alternative explanation.');
    }
    if (recommendation < 12) {
      feedback.add('Give one specific next action or monitoring recommendation.');
    }
    if (feedback.isEmpty) {
      feedback.add('Decision-ready explanation: evidence, impact, uncertainty and action are all present.');
    }

    return ManagerExplanationScore(
      evidence: evidence,
      clarity: clarity,
      businessImpact: businessImpact,
      uncertainty: uncertainty,
      recommendation: recommendation,
      feedback: feedback,
    );
  }

  static int _hits(String text, List<String> terms) =>
      terms.where((term) => text.contains(term.toLowerCase())).length;
}
