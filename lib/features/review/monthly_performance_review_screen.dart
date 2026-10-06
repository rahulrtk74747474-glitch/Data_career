import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/interview_result.dart';
import '../../models/skill_mastery.dart';
import '../game/game_providers.dart';

class MonthlyPerformanceReviewScreen extends ConsumerWidget {
  const MonthlyPerformanceReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final skills = ref.watch(skillProfileProvider);
    final portfolio = ref.watch(portfolioSnapshotProvider);
    final interviews = ref.watch(interviewResultsProvider);
    final readiness = ref.watch(jobReadinessProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Performance Review')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${_monthName(now.month)} ${now.year} review',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              '${progress.role} • ${progress.companyName}',
            ),
            const SizedBox(height: 16),
            skills.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('$error'),
              data: (items) => _SkillReview(skills: items),
            ),
            const SizedBox(height: 12),
            portfolio.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('$error'),
              data: (snapshot) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Evidence delivered',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${snapshot.evidenceCount} evidence items • ${snapshot.attempts.length} recorded attempts',
                      ),
                      Text(
                        'Best ticket/lab: ${snapshot.strongestTask == null ? 'None yet' : '${snapshot.strongestTask!.title} (${snapshot.strongestTask!.bestScore}/100)'}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            interviews.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('$error'),
              data: (items) => _InterviewReview(results: items),
            ),
            const SizedBox(height: 12),
            readiness.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text('$error'),
              data: (report) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manager summary',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(_managerSummary(report.totalScore)),
                      const SizedBox(height: 8),
                      Text(
                        'Job Readiness: ${report.totalScore}/100',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Next-month focus',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      for (final item in report.remediation.take(3))
                        Text('• $item'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company pulse',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Revenue index: ${progress.revenueIndex.toStringAsFixed(1)}',
                    ),
                    Text(
                      'Churn: ${progress.churnRate.toStringAsFixed(1)}%',
                    ),
                    Text(
                      'Cost index: ${progress.costIndex.toStringAsFixed(1)}',
                    ),
                    Text(
                      'Satisfaction: ${progress.satisfaction.toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _managerSummary(int readiness) {
    if (readiness >= 85) {
      return 'You are consistently producing strong evidence across technical analysis and communication. Keep practicing under time pressure and protect quality as complexity increases.';
    }
    if (readiness >= 70) {
      return 'You are operating reliably in several analyst skills. The next step is to reduce weak-domain variance and make your written recommendations more consistently decision-ready.';
    }
    if (readiness >= 50) {
      return 'Progress is visible, but execution is still uneven. Focus on the lowest mastery domains and repeat end-to-end cases before increasing difficulty.';
    }
    return 'Build the fundamentals first: complete placement, practice core SQL/spreadsheet tasks and use the review queue until the basic workflow becomes consistent.';
  }

  static String _monthName(int month) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][month - 1];
}

class _SkillReview extends StatelessWidget {
  const _SkillReview({required this.skills});

  final List<SkillMastery> skills;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return const SizedBox.shrink();
    final sorted = [...skills]
      ..sort((a, b) => b.mastery.compareTo(a.mastery));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skill scorecard',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final skill in sorted)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Expanded(child: Text(skill.displayName)),
                    Text('${skill.mastery.toStringAsFixed(0)}%'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InterviewReview extends StatelessWidget {
  const _InterviewReview({required this.results});

  final List<InterviewResult> results;

  @override
  Widget build(BuildContext context) {
    final best = results.isEmpty
        ? 0
        : results
            .map((item) => item.bestScore)
            .reduce((a, b) => a > b ? a : b);
    final attempts = results.fold<int>(
      0,
      (sum, item) => sum + item.attempts,
    );

    return Card(
      child: ListTile(
        leading: const Icon(Icons.record_voice_over_outlined),
        title: const Text('Interview practice'),
        subtitle: Text('$attempts attempts • best score $best/100'),
      ),
    );
  }
}
