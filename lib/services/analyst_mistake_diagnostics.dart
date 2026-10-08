/// Explains observable failure signatures, not an invented explanation of intent.
class AnalystMistakeDiagnostics {
  const AnalystMistakeDiagnostics._();

  static String sql({
    required String query,
    required String graderFeedback,
    required int actualRowCount,
    required int expectedRowCount,
  }) {
    final q = query.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final points = <String>[];
    if (q.contains('join') && actualRowCount > expectedRowCount) {
      points.add('Possible many-to-many join: verify JOIN-key uniqueness and inspect row counts before/after the join.');
    }
    if (actualRowCount != expectedRowCount) {
      points.add('Grain mismatch: expected $expectedRowCount row(s) but got $actualRowCount. Check grouping keys, filters and duplicates.');
    }
    if (q.contains('join') && !RegExp(r'\bon\b|\busing\s*\(').hasMatch(q)) {
      points.add('Check join predicates. Missing or broad join conditions can multiply rows.');
    }
    if (!q.contains('where') && !q.contains('having')) {
      points.add('Verify the eligible population: status, date and active-record filters may be required.');
    }
    if (q.contains('avg(') && (q.contains('ratio') || q.contains('rate'))) {
      points.add('Denominator check: AVG of percentages can differ from SUM(numerator)/SUM(denominator).');
    }
    if (points.isEmpty) {
      points.add('Reconcile one group to raw records. Check nulls, units, filters and join cardinality.');
    }
    return graderFeedback + '\nDiagnostic hypotheses to verify:\n• ' + points.join('\n• ');
  }

  static String? managerOverclaim(String answer) {
    final text = answer.toLowerCase();
    final absoluteClaim = RegExp(
      r'\b(proves?|definitely|guarantees?|always|never|caused|causes)\b',
    ).hasMatch(text);
    final qualified = RegExp(
      r'\b(not|cannot|does not|may|might|could|uncertain|unless|without)\b',
    ).hasMatch(text);
    if (absoluteClaim && !qualified) {
      return 'Causal overclaim: observational differences do not establish causality. Explain a plausible alternative or propose a validation test.';
    }
    return null;
  }
}
