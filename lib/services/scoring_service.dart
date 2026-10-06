import '../models/analyst_task.dart';

class GradeResult {
  const GradeResult({
    required this.isCorrect,
    required this.feedback,
  });

  final bool isCorrect;
  final String feedback;
}

class ScoringService {
  const ScoringService._();

  static GradeResult grade(AnalystTask task, String rawAnswer) {
    final answer = rawAnswer.trim();

    if (answer.isEmpty) {
      return const GradeResult(
        isCorrect: false,
        feedback: 'Enter an answer before submitting.',
      );
    }

    switch (task.answerType) {
      case 'formula':
        final normalized = _normalizeFormula(answer);
        final expected = _normalizeFormula(task.expectedAnswer);
        return GradeResult(
          isCorrect: normalized == expected,
          feedback: normalized == expected
              ? 'Correct. Your formula produces the requested business value.'
              : 'Not yet. Check the row references, arithmetic order, and whether the discount is applied correctly.',
        );

      case 'sql_tokens':
        final normalized = _normalizeSql(answer);
        final missing = task.requiredTokens
            .where(
              (token) => !normalized.contains(_normalizeSql(token)),
            )
            .toList();

        return GradeResult(
          isCorrect: missing.isEmpty,
          feedback: missing.isEmpty
              ? 'Correct. Your query contains the required selection, aggregation, source, and grouping logic.'
              : 'Not yet. Your query is missing part of the requested logic. Use a hint if you need a smaller clue.',
        );

      case 'choice':
        final correct = answer == task.expectedAnswer;
        return GradeResult(
          isCorrect: correct,
          feedback: correct
              ? 'Correct. That recommendation matches the evidence without overstating causation.'
              : 'Not yet. Choose the recommendation that the available evidence can actually support.',
        );

      default:
        return const GradeResult(
          isCorrect: false,
          feedback: 'This task type is not supported yet.',
        );
    }
  }

  static String _normalizeFormula(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(r'$', '')
        .toUpperCase();
  }

  static String _normalizeSql(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(';', '')
        .trim();
  }
}
