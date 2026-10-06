import '../models/dashboard_challenge.dart';

class DashboardGrade {
  const DashboardGrade({
    required this.isCorrect,
    required this.feedback,
  });

  final bool isCorrect;
  final String feedback;
}

class DashboardScoringService {
  const DashboardScoringService._();

  static DashboardGrade grade(
    DashboardChallenge challenge,
    String answer,
  ) {
    if (answer.isEmpty) {
      return const DashboardGrade(
        isCorrect: false,
        feedback: 'Choose an answer before submitting.',
      );
    }

    final correct = answer == challenge.correctOption;
    return DashboardGrade(
      isCorrect: correct,
      feedback: correct
          ? 'Correct. That design choice best matches the decision and data grain.'
          : 'Not yet. Re-check the decision, metric definition, comparison grain, and potential for visual distortion.',
    );
  }
}
