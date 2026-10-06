import '../features/game/game_progress.dart';
import '../models/boss_case_result.dart';
import '../models/capstone_result.dart';
import '../models/evidence_attempt.dart';
import '../models/interview_result.dart';
import '../models/job_readiness.dart';
import '../models/skill_mastery.dart';

class JobReadinessService {
  const JobReadinessService._();

  static JobReadinessReport calculate({
    required GameProgress progress,
    required List<SkillMastery> skills,
    required List<BossCaseResult> bossCases,
    required List<InterviewResult> interviews,
    required List<EvidenceAttempt> evidence,
    required CapstoneResult? capstone,
  }) {
    final byKey = {
      for (final skill in skills) skill.skillKey: skill.mastery.clamp(0, 100),
    };

    double mastery(String key) => (byKey[key] ?? 0).toDouble();
    final preparation =
        (mastery('spreadsheets') + mastery('cleaning')) / 2;

    final interviewScore = interviews.isEmpty
        ? 0.0
        : interviews.fold<double>(
              0,
              (sum, item) => sum + item.bestScore,
            ) /
            interviews.length;

    final domains = <ReadinessDomain>[
      ReadinessDomain(
        key: 'sql',
        label: 'SQL',
        score: mastery('sql'),
        recommendation:
            'Use SQL Workstation and Advanced SQL tickets until joins, grouping, filters and conditional aggregation are reliable.',
      ),
      ReadinessDomain(
        key: 'data_prep',
        label: 'Spreadsheets & Cleaning',
        score: preparation,
        recommendation:
            'Practice formulas, validation, duplicates, missing values, formats and category standardization.',
      ),
      ReadinessDomain(
        key: 'statistics',
        label: 'Statistics',
        score: mastery('statistics'),
        recommendation:
            'Review uncertainty, sampling, hypothesis tests, experiments and correlation-versus-causation reasoning.',
      ),
      ReadinessDomain(
        key: 'python',
        label: 'Python/Pandas',
        score: mastery('python'),
        recommendation:
            'Repeat Pandas filtering, missing-value, groupby, derived-column and top-N workflows.',
      ),
      ReadinessDomain(
        key: 'business',
        label: 'Business Communication',
        score: mastery('business'),
        recommendation:
            'Practice KPI framing, bounded recommendations and executive communication in Boss Cases.',
      ),
      ReadinessDomain(
        key: 'interviews',
        label: 'Interviews',
        score: interviewScore,
        recommendation:
            'Use Interview Mode and the timed Interview Gauntlet; target structured answers and evidence-based reasoning.',
      ),
    ];

    final skillFoundation = domains
            .where((item) => item.key != 'interviews')
            .fold<double>(0, (sum, item) => sum + item.score) /
        5;

    final bossAverage = bossCases.isEmpty
        ? 0.0
        : bossCases.fold<double>(
              0,
              (sum, item) => sum + item.totalScore,
            ) /
            bossCases.length;

    final evidenceScore = _evidenceScore(evidence);
    final completionScore = _completionScore(progress);
    final capstoneScore = (capstone?.totalScore ?? 0).toDouble();

    final total = (
      skillFoundation * 0.50 +
      interviewScore * 0.15 +
      bossAverage * 0.10 +
      evidenceScore * 0.10 +
      completionScore * 0.05 +
      capstoneScore * 0.10
    ).round().clamp(0, 100);

    final remediation = <String>[
      for (final domain in domains)
        if (domain.score < 75)
          '${domain.label}: ${domain.recommendation}',
      if (bossAverage < 75)
        'Boss Cases: strengthen end-to-end analysis across cleaning, SQL, KPI, visual choice and recommendation.',
      if (evidenceScore < 70)
        'Evidence breadth: complete more distinct high-quality tickets, interviews and cases across company chapters.',
      if (!progress.companyJourneyCompleted)
        'Company journey: complete all five company chapters before graduation.',
      if (capstoneScore < 80)
        'Capstone: reach at least 80/100 on the final cross-company capstone.',
    ];

    if (remediation.isEmpty) {
      remediation.add(
        'Maintain readiness with spaced review and timed interview practice.',
      );
    }

    return JobReadinessReport(
      totalScore: total,
      domains: domains,
      skillFoundationScore: skillFoundation,
      interviewScore: interviewScore,
      bossCaseScore: bossAverage,
      evidenceScore: evidenceScore,
      completionScore: completionScore,
      capstoneScore: capstoneScore,
      remediation: remediation,
    );
  }

  static double _evidenceScore(List<EvidenceAttempt> evidence) {
    if (evidence.isEmpty) return 0;

    final bestBySource = <String, int>{};
    final companies = <String>{};
    for (final item in evidence) {
      final key = '${item.sourceType}:${item.sourceId}';
      final current = bestBySource[key];
      if (current == null || item.score > current) {
        bestBySource[key] = item.score;
      }
      if (item.companyKey != 'career' &&
          item.companyKey != 'cross_company') {
        companies.add(item.companyKey);
      }
    }

    final quality = bestBySource.values.fold<double>(
          0,
          (sum, score) => sum + score,
        ) /
        bestBySource.length;
    final breadth = (bestBySource.length * 8).clamp(0, 100).toDouble();
    final companyBreadth = (companies.length * 20).clamp(0, 100).toDouble();

    return (quality * 0.60 + breadth * 0.25 + companyBreadth * 0.15)
        .clamp(0, 100);
  }

  static double _completionScore(GameProgress progress) {
    final rolePart =
        (progress.careerLevel / (GameProgress.roleNames.length - 1)) * 50;
    final companyPart =
        (progress.resolvedCompanyChapter / (GameProgress.companyKeys.length - 1)) *
            40;
    final journeyPart = progress.companyJourneyCompleted ? 10.0 : 0.0;
    return (rolePart + companyPart + journeyPart).clamp(0, 100);
  }
}
