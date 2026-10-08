import '../models/analyst_task.dart';

class MistakeFeedbackService {
  const MistakeFeedbackService._();

  static String explain({
    required AnalystTask task,
    required String answer,
    required String baseFeedback,
  }) {
    final normalized = answer.toLowerCase();
    final expected = task.solutionText.toLowerCase();
    final explanation = task.explanation.toLowerCase();
    final details = <String>[];

    if (task.requiredTokens.isNotEmpty) {
      final missing = task.requiredTokens
          .where((token) => !normalized.contains(token.toLowerCase()))
          .toList();
      if (missing.isNotEmpty) {
        details.add(
          'Missing required concept/syntax: ${missing.take(4).join(', ')}.',
        );
      }
    }

    if (task.answerType == 'sql_result') {
      if (expected.contains('join') && !normalized.contains('join')) {
        details.add(
          'This task needs data from related tables. Check the JOIN key and expected row grain before aggregating.',
        );
      }
      if (expected.contains('group by') && !normalized.contains('group by')) {
        details.add(
          'The result needs one aggregate row per business group, so check GROUP BY.',
        );
      }
      if (expected.contains('where') && !normalized.contains('where')) {
        details.add(
          'The business definition filters rows. Check the WHERE condition before aggregating.',
        );
      }
      if (normalized.contains('select *')) {
        details.add(
          'SELECT * may return the wrong shape. Return only the columns required by the deliverable.',
        );
      }
    }

    if ((explanation.contains('outlier') || explanation.contains('skew')) &&
        (normalized.contains('mean') || normalized.contains('average')) &&
        expected.contains('median')) {
      details.add(
        'The distribution contains an extreme/skewed value. Mean can be pulled away from the typical observation; compare the median.',
      );
    }

    if ((task.context.toLowerCase().contains('conversion') ||
            task.prompt.toLowerCase().contains('rate')) &&
        explanation.contains('denominator')) {
      details.add(
        'Re-check the denominator. A rate is only meaningful when numerator and eligible population match the business definition.',
      );
    }

    if (details.isEmpty) {
      final firstSentence = task.explanation
          .split(RegExp(r'[.!?]'))
          .map((part) => part.trim())
          .firstWhere((part) => part.isNotEmpty, orElse: () => '');
      if (firstSentence.isNotEmpty) {
        details.add('Key idea to revisit: $firstSentence.');
      }
    }

    return [
      baseFeedback.trim(),
      ...details,
    ].where((line) => line.isNotEmpty).join('\n');
  }
}
