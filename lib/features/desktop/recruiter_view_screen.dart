import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_providers.dart';

class RecruiterViewScreen extends ConsumerWidget {
  const RecruiterViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readiness = ref.watch(jobReadinessProvider);
    final skills = ref.watch(skillProfileProvider);
    final portfolio = ref.watch(portfolioSnapshotProvider);
    final interviews = ref.watch(interviewResultsProvider);
    final progress = ref.watch(gameProgressProvider);

    if (readiness.isLoading ||
        skills.isLoading ||
        portfolio.isLoading ||
        interviews.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recruiter View')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final error =
        readiness.error ?? skills.error ?? portfolio.error ?? interviews.error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recruiter View')),
        body: Center(child: Text('$error')),
      );
    }

    final skillList = [...skills.value!]
      ..sort((a, b) => b.mastery.compareTo(a.mastery));
    final projects = progress.rewardedLearningIds
        .where((id) => id.startsWith('mission:'))
        .length;
    final independentEvidence = portfolio.value!.taskPerformances.where(
      (item) {
        final d = item.difficulty.toLowerCase();
        return d == 'independent' || d == 'project' || d == 'advanced';
      },
    ).length;
    final interviewBest = interviews.value!.isEmpty
        ? 0
        : interviews.value!
            .map((item) => item.bestScore)
            .reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Recruiter View')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Candidate evidence summary',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This view emphasizes demonstrated ability instead of streaks or XP.',
            ),
            const SizedBox(height: 16),
            _StatCard(
              title: 'Job Readiness',
              value: '${readiness.value!.totalScore}/100',
              detail: 'Evidence-weighted readiness',
            ),
            _StatCard(
              title: 'Career Projects',
              value: '$projects',
              detail: 'Connected multi-skill company projects',
            ),
            _StatCard(
              title: 'Independent Evidence',
              value: '$independentEvidence',
              detail: 'Advanced/project/independent task records',
            ),
            _StatCard(
              title: 'Best Interview',
              value: '$interviewBest/100',
              detail: 'Best demonstrated interview score',
            ),
            const SizedBox(height: 12),
            Text(
              'Verified skill profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            for (final skill in skillList)
              Card(
                child: ListTile(
                  title: Text(skill.displayName),
                  subtitle: LinearProgressIndicator(
                    value: skill.mastery.clamp(0, 100) / 100,
                  ),
                  trailing: Text('${skill.mastery.toStringAsFixed(0)}%'),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Evidence portfolio: ${portfolio.value!.evidenceCount} unique items • '
              '${portfolio.value!.attemptCount} recorded attempts',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.detail,
  });

  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(detail),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
