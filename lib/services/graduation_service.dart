import '../features/game/game_progress.dart';
import '../models/capstone_result.dart';
import '../models/interview_result.dart';
import '../models/job_readiness.dart';

class GraduationService {
  const GraduationService._();

  static GraduationEligibility evaluate({
    required GameProgress progress,
    required JobReadinessReport readiness,
    required CapstoneResult? capstone,
    required InterviewResult? gauntlet,
  }) {
    final coreDomains = readiness.domains
        .where((domain) => domain.key != 'interviews')
        .toList();
    final minimumCore = coreDomains.isEmpty
        ? 0.0
        : coreDomains
            .map((domain) => domain.score)
            .reduce((a, b) => a < b ? a : b);

    return GraduationEligibility(
      criteria: [
        GraduationCriterion(
          label: 'Five-company journey',
          met: progress.companyJourneyCompleted,
          detail: progress.companyJourneyCompleted
              ? 'Completed'
              : 'Complete the final Logistics company review.',
        ),
        GraduationCriterion(
          label: 'Final capstone',
          met: (capstone?.totalScore ?? 0) >= 80,
          detail: '${capstone?.totalScore ?? 0} / 80 required',
        ),
        GraduationCriterion(
          label: 'Job Readiness Score',
          met: readiness.totalScore >= 80,
          detail: '${readiness.totalScore} / 80 required',
        ),
        GraduationCriterion(
          label: 'Interview Gauntlet',
          met: (gauntlet?.bestScore ?? 0) >= 75,
          detail: '${gauntlet?.bestScore ?? 0} / 75 required',
        ),
        GraduationCriterion(
          label: 'No critical skill gap',
          met: minimumCore >= 65,
          detail:
              '${minimumCore.toStringAsFixed(0)}% weakest core domain / 65% required',
        ),
      ],
    );
  }
}
