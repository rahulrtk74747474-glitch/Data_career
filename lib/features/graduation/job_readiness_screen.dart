import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/interview_result.dart';
import '../../models/job_readiness.dart';
import '../game/game_providers.dart';
import '../interview/interview_session_screen.dart';
import '../portfolio/portfolio_screen.dart';
import 'certificate_screen.dart';
import 'final_capstone_screen.dart';
import 'independent_sql_exam_screen.dart';
import 'resume_builder_screen.dart';

class JobReadinessScreen extends ConsumerWidget {
  const JobReadinessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final report = ref.watch(jobReadinessProvider);
    final eligibility = ref.watch(graduationEligibilityProvider);
    final capstone = ref.watch(capstoneResultProvider);
    final gauntlet = ref.watch(interviewGauntletProvider);
    final interviews = ref.watch(interviewResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Job Readiness & Graduation')),
      body: SafeArea(
        child: report.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not calculate job readiness.\n$error'),
          ),
          data: (readiness) {
            final gauntletResult = _findGauntlet(
              interviews.valueOrNull ?? const <InterviewResult>[],
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ReadinessHero(report: readiness),
                const SizedBox(height: 14),
                Text(
                  'Readiness breakdown',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final domain in readiness.domains)
                  _DomainCard(domain: domain),
                const SizedBox(height: 14),
                _FormulaCard(report: readiness),
                const SizedBox(height: 14),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Scores show in-app training progress'),
                    subtitle: Text(
                      'They do not independently predict job offers or prove '
                      'competence in Microsoft Excel, Power BI or native Pandas. '
                      'Use practical examinations and externally replayed projects.',
                    ),
                  ),
                ),
                Text(
                  'Final hiring preparation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: const Text('Final cross-company capstone'),
                    subtitle: Text(
                      capstone.valueOrNull == null
                          ? progress.companyJourneyCompleted
                              ? 'Not attempted • graduation threshold 80/100'
                              : 'Complete the five-company journey first'
                          : 'Latest saved score: ${capstone.valueOrNull!.totalScore}/100',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    enabled: progress.companyJourneyCompleted,
                    onTap: progress.companyJourneyCompleted
                        ? () => _open(
                              context,
                              const FinalCapstoneScreen(),
                            )
                        : null,
                  ),
                ),
                gauntlet.when(
                  loading: () => const Card(
                    child: ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Loading Interview Gauntlet'),
                    ),
                  ),
                  error: (error, stackTrace) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: const Text('Interview Gauntlet unavailable'),
                      subtitle: Text('$error'),
                    ),
                  ),
                  data: (round) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: const Text('Interview Gauntlet'),
                      subtitle: Text(
                        gauntletResult == null
                            ? 'Mixed timed SQL, statistics, case and behavioral loop • 15 minutes'
                            : 'Best: ${gauntletResult.bestScore}/100 • ${gauntletResult.attempts} attempts',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      enabled: progress.companyJourneyCompleted,
                      onTap: progress.companyJourneyCompleted
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => InterviewSessionScreen(
                                    round: round,
                                    timed: true,
                                  ),
                                ),
                              )
                          : null,
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: const Text('Unseen independent SQL practical exam'),
                    subtitle: const Text(
                      'Execute your own SQL, without hints, on an unfamiliar '
                      'dataset and survive a changed-data verification.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(
                      context,
                      const IndependentSqlExamScreen(),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Resume Bullet Builder'),
                    subtitle: const Text(
                      'Editable bullets generated only from recorded evidence',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        _open(context, const ResumeBuilderScreen()),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.work_outline),
                    title: const Text('Portfolio Evidence'),
                    subtitle: const Text(
                      'Project cards, strongest scores and attempt history',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(context, const PortfolioScreen()),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Targeted remediation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final item in readiness.remediation)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.build_outlined),
                      title: Text(item),
                    ),
                  ),
                const SizedBox(height: 14),
                Text(
                  'Graduation gates',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                eligibility.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => Text('$error'),
                  data: (status) => Column(
                    children: [
                      for (final criterion in status.criteria)
                        Card(
                          child: ListTile(
                            leading: Icon(
                              criterion.met
                                  ? Icons.check_circle
                                  : Icons.lock_outline,
                            ),
                            title: Text(criterion.label),
                            subtitle: Text(criterion.detail),
                          ),
                        ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: status.eligible
                            ? () => _open(
                                  context,
                                  const CertificateScreen(),
                                )
                            : null,
                        icon: const Icon(Icons.workspace_premium_outlined),
                        label: Text(
                          status.eligible
                              ? 'Generate completion certificate'
                              : 'Certificate locked',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  InterviewResult? _findGauntlet(List<InterviewResult> results) {
    for (final result in results) {
      if (result.roundKey == 'job_readiness_gauntlet') return result;
    }
    return null;
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }
}

class _ReadinessHero extends StatelessWidget {
  const _ReadinessHero({required this.report});

  final JobReadinessReport report;

  @override
  Widget build(BuildContext context) {
    final label = report.totalScore >= 80
        ? 'Job-ready evidence threshold reached'
        : report.totalScore >= 65
            ? 'Approaching job-ready threshold'
            : 'Build more evidence before graduation';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              '${report.totalScore}/100',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Job Readiness Score',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: report.totalScore / 100),
          ],
        ),
      ),
    );
  }
}

class _DomainCard extends StatelessWidget {
  const _DomainCard({required this.domain});

  final ReadinessDomain domain;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(domain.label)),
                Text('${domain.score.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: domain.score / 100),
            if (domain.score < 75) ...[
              const SizedBox(height: 8),
              Text(domain.recommendation),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.report});

  final JobReadinessReport report;

  @override
  Widget build(BuildContext context) {
    final factors = [
      ('Skill foundation', 50, report.skillFoundationScore),
      ('Interviews', 15, report.interviewScore),
      ('Boss Cases', 10, report.bossCaseScore),
      ('Immutable evidence', 10, report.evidenceScore),
      ('Career + companies', 5, report.completionScore),
      ('Final capstone', 10, report.capstoneScore),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How the score is calculated',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'XP is intentionally excluded. The score is based on demonstrated skill and evidence.',
            ),
            const SizedBox(height: 10),
            for (final factor in factors)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '${factor.$1}: ${factor.$2}% weight • ${factor.$3.toStringAsFixed(0)}% evidence score',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
