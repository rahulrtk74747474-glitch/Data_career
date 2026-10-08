/// Offline concept rubrics for independent flagship decisions.
/// These grade reasoning signals, not executable Python or Power BI results.
class OpenEndedDecisionGrade {
  const OpenEndedDecisionGrade(this.score, this.feedback, this.missingConcepts);
  final int score;
  final String feedback;
  final List<String> missingConcepts;
  bool get passed => score >= 70;
}

class OpenEndedDecisionService {
  const OpenEndedDecisionService._();

  static const Map<String, Map<String, List<List<String>>>> rubrics = {
    'flagship-ecommerce-revenue': {
      'statistics': [
        ['enterprise', 'segment'], ['refund', 'return'],
        ['margin', 'profit'], ['mix', 'cause', 'causal', 'confound'],
      ],
      'chart': [
        ['segment'], ['revenue'], ['refund', 'margin'],
        ['trend', 'time', 'daily'],
      ],
    },
    'flagship-saas-retention': {
      'statistics': [
        ['survivor', 'retained sample'], ['churn', 'inactive'],
        ['bias', 'disappear', 'excluded'], ['retention', 'retained'],
      ],
      'chart': [
        ['cohort'], ['retention'], ['mrr', 'nrr'],
        ['heatmap', 'segment'],
      ],
    },
    'flagship-bank-risk': {
      'statistics': [
        ['denominator', 'loan book', 'portfolio size'],
        ['ratio', 'percentage', 'rate'],
        ['exposure', 'outstanding', 'absolute'],
        ['grow', 'growth', 'grew', 'expanded'],
      ],
      'chart': [
        ['exposure', 'outstanding'], ['risk band', 'band', 'risk group'],
        ['share', 'amount', 'absolute'],
        ['trend', 'delinquen', 'over time'],
      ],
    },
    'flagship-hospital-capacity': {
      'statistics': [
        ['simpson', 'composition', 'mix'], ['aggregate', 'overall'],
        ['subgroup', 'unit', 'department'],
        ['different', 'move', 'trend', 'mask'],
      ],
      'chart': [
        ['wait'], ['unit', 'department'],
        ['median', 'p90', 'percentile'],
        ['capacity', 'day', 'staff', 'trend'],
      ],
    },
    'flagship-logistics-sla': {
      'statistics': [
        ['cost', 'spend'],
        ['efficien', 'normalized', 'per kg', 'per shipment'],
        ['weight', 'route'], ['mix', 'change', 'investigate'],
      ],
      'chart': [
        ['route'], ['cost/kg', 'cost per kg', 'cost'],
        ['sla', 'late', 'on-time'], ['trend', 'p90', 'time'],
      ],
    },
  };

  static OpenEndedDecisionGrade grade({
    required String workdayId,
    required String stage,
    required String answer,
  }) {
    final groups = rubrics[workdayId]?[stage];
    if (groups == null || groups.isEmpty) {
      return const OpenEndedDecisionGrade(0, 'The offline rubric is unavailable.', []);
    }
    final normalized = answer.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final words = normalized.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    final missing = <String>[];
    var matches = 0;
    for (final alternatives in groups) {
      if (alternatives.any(normalized.contains)) {
        matches++;
      } else {
        missing.add(alternatives.first);
      }
    }
    // A row of buzzwords is not a defensible business decision.
    final isExplanation = words >= (stage == 'statistics' ? 12 : 9);
    final coverage = (matches * 100 / groups.length).round();
    final score = isExplanation ? coverage : coverage.clamp(0, 55).toInt();
    final feedback = score >= 70
        ? 'The offline concept rubric accepted this reasoning. Verify the data and defend your assumptions.'
        : 'Explain your reasoning in full sentences. Revisit: ${missing.join(', ')}. ${isExplanation ? '' : 'Your answer is too short to demonstrate reasoning.'}';
    return OpenEndedDecisionGrade(score, feedback, missing);
  }
}
