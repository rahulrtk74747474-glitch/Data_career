import '../models/interview.dart';

class InterviewQuestionScore {
  const InterviewQuestionScore({
    required this.score,
    required this.feedback,
  });

  final int score;
  final String feedback;
}

class InterviewScoringService {
  const InterviewScoringService._();

  static InterviewQuestionScore scoreChoice(
    InterviewQuestion question,
    String answer,
  ) {
    final correct = answer == question.expectedAnswer;
    return InterviewQuestionScore(
      score: correct ? 100 : 0,
      feedback: correct
          ? 'Correct. The answer matches the evidence and interview standard.'
          : 'Not yet. Re-check the evidence, assumptions and the exact question being asked.',
    );
  }

  static InterviewQuestionScore scoreRubric(
    InterviewQuestion question,
    String answer,
  ) {
    final normalized = answer.toLowerCase();
    var score = 0;
    final covered = <String>[];
    final missing = <String>[];

    for (final criterion in question.criteria) {
      final matched = criterion.keywords.any(
        (keyword) => normalized.contains(keyword.toLowerCase()),
      );
      if (matched) {
        score += criterion.weight;
        covered.add(criterion.label);
      } else {
        missing.add(criterion.label);
      }
    }

    final feedback = StringBuffer()
      ..write('Rubric score: $score/100.');
    if (covered.isNotEmpty) {
      feedback.write(' Covered: ${covered.join(', ')}.');
    }
    if (missing.isNotEmpty) {
      feedback.write(' Improve: ${missing.join(', ')}.');
    }

    return InterviewQuestionScore(
      score: score.clamp(0, 100),
      feedback: feedback.toString(),
    );
  }
}
