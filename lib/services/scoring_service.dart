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
            .where((token) => !normalized.contains(_normalizeSql(token)))
            .toList();
        return GradeResult(
          isCorrect: missing.isEmpty,
          feedback: missing.isEmpty
              ? 'Correct. Your query contains the requested SQL logic.'
              : 'Not yet. Your query is missing part of the requested logic.',
        );
      case 'choice':
        final correct = answer == task.expectedAnswer;
        return GradeResult(
          isCorrect: correct,
          feedback: correct
              ? 'Correct. That is the strongest answer supported by the evidence.'
              : 'Not yet. Re-check what the evidence can actually support.',
        );
      default:
        return const GradeResult(
          isCorrect: false,
          feedback: 'This task uses a specialized grader.',
        );
    }
  }

  static GradeResult gradeSelections(
    AnalystTask task,
    Set<String> selections,
  ) {
    if (selections.isEmpty) {
      return const GradeResult(
        isCorrect: false,
        feedback: 'Select at least one cleaning action.',
      );
    }

    final actual = selections.toList()..sort();
    final expected = task.expectedSelections.toList()..sort();
    final correct = actual.length == expected.length &&
        List.generate(actual.length, (index) => actual[index] == expected[index])
            .every((matches) => matches);

    return GradeResult(
      isCorrect: correct,
      feedback: correct
          ? 'Correct. You identified the full cleaning plan.'
          : 'Not yet. Some selected actions are unnecessary, or an important data-quality issue is still missing.',
    );
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
