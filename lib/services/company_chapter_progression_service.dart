import '../features/game/game_progress.dart';
import '../models/skill_mastery.dart';

class CompanyChapterCriterion {
  const CompanyChapterCriterion({
    required this.label,
    required this.met,
    required this.detail,
  });

  final String label;
  final bool met;
  final String detail;
}

class CompanyChapterReview {
  const CompanyChapterReview({
    required this.currentChapter,
    required this.targetChapter,
    required this.criteria,
    required this.finalAvailableChapter,
  });

  final int currentChapter;
  final int targetChapter;
  final List<CompanyChapterCriterion> criteria;
  final bool finalAvailableChapter;

  bool get passed => criteria.every((criterion) => criterion.met);

  bool get isJourneyCompletionReview => finalAvailableChapter;
}

class CompanyChapterProgressionService {
  const CompanyChapterProgressionService._();

  static const _minimumCareerLevel = [2, 4, 5, 5, 5];
  static const _minimumCompletedTickets = [5, 4, 4, 5, 6];
  static const _minimumMastery = [55.0, 70.0, 78.0, 82.0, 85.0];
  static const _minimumBossScore = [70, 70, 75, 78, 80];
  static const _minimumInterviewScore = [0, 65, 75, 78, 80];

  static CompanyChapterReview evaluate({
    required GameProgress progress,
    required int completedCurrentCompanyTickets,
    required List<SkillMastery> skills,
    int? bossCaseScore,
    int? interviewScore,
  }) {
    final current = progress.resolvedCompanyChapter;
    final finalAvailable = current >= 4;
    final target = finalAvailable ? current : current + 1;
    final minLevel = _minimumCareerLevel[current];
    final minTickets = _minimumCompletedTickets[current];
    final minMastery = _minimumMastery[current];
    final minBoss = _minimumBossScore[current];
    final minInterview = _minimumInterviewScore[current];

    final attempted = skills.where((skill) => skill.attempts > 0).toList();
    final averageMastery = attempted.isEmpty
        ? 0.0
        : attempted.fold<double>(
              0,
              (sum, skill) => sum + skill.mastery,
            ) /
            attempted.length;

    final criteria = <CompanyChapterCriterion>[
      CompanyChapterCriterion(
        label: 'Career role',
        met: progress.careerLevel >= minLevel,
        detail:
            '${progress.role} • requires ${GameProgress.roleNames[minLevel]} or higher',
      ),
      CompanyChapterCriterion(
        label: 'Current-company tickets',
        met: completedCurrentCompanyTickets >= minTickets,
        detail: '$completedCurrentCompanyTickets / $minTickets completed',
      ),
      CompanyChapterCriterion(
        label: 'Average attempted-skill mastery',
        met: averageMastery >= minMastery,
        detail:
            '${averageMastery.toStringAsFixed(0)}% / ${minMastery.toStringAsFixed(0)}%',
      ),
      CompanyChapterCriterion(
        label: 'Current-company Boss Case',
        met: (bossCaseScore ?? 0) >= minBoss,
        detail: '${bossCaseScore ?? 0} / $minBoss',
      ),
    ];

    if (minInterview > 0) {
      criteria.add(
        CompanyChapterCriterion(
          label: 'Interview readiness',
          met: (interviewScore ?? 0) >= minInterview,
          detail: '${interviewScore ?? 0} / $minInterview',
        ),
      );
    }

    return CompanyChapterReview(
      currentChapter: current,
      targetChapter: target,
      criteria: criteria,
      finalAvailableChapter: false,
    );
  }
}
