import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/foundation_lesson.dart';
import '../../models/portfolio_snapshot.dart';
import '../../models/skill_mastery.dart';
import '../game/game_providers.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(skillProfileProvider);
    final academy = ref.watch(foundationLessonsProvider);
    final portfolio = ref.watch(portfolioSnapshotProvider);
    final progress = ref.watch(gameProgressProvider);

    if (profile.isLoading || academy.isLoading || portfolio.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Skills & Job Readiness')),
        body: const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final error = profile.error ?? academy.error ?? portfolio.error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Skills & Job Readiness')),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load your skill profile.\n$error'),
            ),
          ),
        ),
      );
    }

    final skills = profile.valueOrNull ?? const <SkillMastery>[];
    final lessons = academy.valueOrNull ?? const <FoundationLesson>[];
    final snapshot = portfolio.valueOrNull ??
        const PortfolioSnapshot(taskPerformances: [], bossCases: []);

    final now = DateTime.now().toUtc();
    final weak = skills.where((skill) => skill.isWeak).toList();
    final due = skills.where((skill) => skill.isDue(now)).toList();

    final readiness = [
      _readiness(
        label: 'SQL',
        trackKey: 'sql',
        masteryKey: 'sql',
        lessons: lessons,
        skills: skills,
        portfolio: snapshot,
        rewardedIds: progress.rewardedLearningIds,
      ),
      _readiness(
        label: 'Excel / Spreadsheets',
        trackKey: 'spreadsheets',
        masteryKey: 'spreadsheets',
        lessons: lessons,
        skills: skills,
        portfolio: snapshot,
        rewardedIds: progress.rewardedLearningIds,
      ),
      _readiness(
        label: 'Data Cleaning',
        trackKey: 'cleaning',
        masteryKey: 'cleaning',
        lessons: lessons,
        skills: skills,
        portfolio: snapshot,
        rewardedIds: progress.rewardedLearningIds,
      ),
      _readiness(
        label: 'Statistics',
        trackKey: 'statistics',
        masteryKey: 'statistics',
        lessons: lessons,
        skills: skills,
        portfolio: snapshot,
        rewardedIds: progress.rewardedLearningIds,
      ),
      _readiness(
        label: 'Python / Pandas',
        trackKey: 'python',
        masteryKey: 'python',
        lessons: lessons,
        skills: skills,
        portfolio: snapshot,
        rewardedIds: progress.rewardedLearningIds,
      ),
      _readiness(
        label: 'Dashboards & KPIs',
        trackKey: 'dashboards',
        masteryKey: 'business',
        lessons: lessons,
        skills: skills,
        portfolio: snapshot,
        rewardedIds: progress.rewardedLearningIds,
      ),
      _readiness(
        label: 'Power BI',
        trackKey: 'powerbi',
        masteryKey: 'powerbi',
        lessons: lessons,
        skills: skills,
        portfolio: snapshot,
        rewardedIds: progress.rewardedLearningIds,
      ),
      _readiness(
        label: 'Business Analytics',
        trackKey: 'business',
        masteryKey: 'business',
        lessons: lessons,
        skills: skills,
        portfolio: snapshot,
        rewardedIds: progress.rewardedLearningIds,
      ),
    ];

    final interviewReady =
        readiness.where((item) => item.stage == 'Interview-ready').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Skills & Job Readiness')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Your analyst profile',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '${weak.length} weak topics • ${due.length} due for review',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 330,
              child: _SkillRadar(skills: skills),
            ),
            const SizedBox(height: 18),
            _JobReadySummary(
              ready: interviewReady,
              total: readiness.length,
            ),
            const SizedBox(height: 12),
            Text(
              'Job-ready skill map',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'A high quiz score is not enough. Each skill moves through Learn → Practice → Project → Interview-ready.',
            ),
            const SizedBox(height: 10),
            for (final item in readiness) ...[
              _ReadinessCard(item: item),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            Text(
              'Mastery & review schedule',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            for (final skill in skills)
              Card(
                child: ListTile(
                  title: Text(skill.displayName),
                  subtitle: Text(
                    skill.nextReviewAt == null
                        ? 'No review scheduled yet'
                        : 'Next review: ${_formatDate(skill.nextReviewAt!)}',
                  ),
                  trailing: Text(
                    '${skill.mastery.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            if (weak.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Focus next',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(weak.map((skill) => skill.displayName).join(' • ')),
            ],
          ],
        ),
      ),
    );
  }

  static _SkillReadiness _readiness({
    required String label,
    required String trackKey,
    required String masteryKey,
    required List<FoundationLesson> lessons,
    required List<SkillMastery> skills,
    required PortfolioSnapshot portfolio,
    required Set<String> rewardedIds,
  }) {
    final trackLessons =
        lessons.where((lesson) => lesson.trackKey == trackKey).toList();
    final foundationCompleted = trackLessons
        .where((lesson) => rewardedIds.contains('academy:${lesson.id}'))
        .length;

    double mastery = 0;
    for (final skill in skills) {
      if (skill.skillKey == masteryKey) {
        mastery = skill.mastery;
        break;
      }
    }

    final projectEvidence = portfolio.taskPerformances.where((item) {
      if (item.skillKey != masteryKey) return false;
      final difficulty = item.difficulty.toLowerCase();
      return difficulty != 'foundation' &&
          difficulty != 'guided' &&
          difficulty != 'assisted';
    }).length;

    String stage;
    String nextAction;
    if (trackLessons.isNotEmpty &&
        foundationCompleted < trackLessons.length) {
      stage = 'Learn';
      nextAction =
          'Finish ${trackLessons.length - foundationCompleted} foundation lesson(s).';
    } else if (mastery < 70) {
      stage = 'Practice';
      nextAction =
          'Raise mastery from ${mastery.toStringAsFixed(0)}% to at least 70%.';
    } else if (projectEvidence < 3) {
      stage = 'Project';
      nextAction =
          'Complete ${3 - projectEvidence} more independent/project evidence item(s).';
    } else {
      stage = 'Interview-ready';
      nextAction =
          'Maintain mastery with reviews and practise interview explanations.';
    }

    return _SkillReadiness(
      label: label,
      stage: stage,
      foundationCompleted: foundationCompleted,
      foundationTotal: trackLessons.length,
      mastery: mastery,
      evidence: projectEvidence,
      nextAction: nextAction,
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

class _SkillReadiness {
  const _SkillReadiness({
    required this.label,
    required this.stage,
    required this.foundationCompleted,
    required this.foundationTotal,
    required this.mastery,
    required this.evidence,
    required this.nextAction,
  });

  final String label;
  final String stage;
  final int foundationCompleted;
  final int foundationTotal;
  final double mastery;
  final int evidence;
  final String nextAction;
}

class _JobReadySummary extends StatelessWidget {
  const _JobReadySummary({
    required this.ready,
    required this.total,
  });

  final int ready;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$ready / $total core skill areas interview-ready',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total == 0 ? 0 : ready / total,
            ),
            const SizedBox(height: 8),
            const Text(
              'Job readiness requires foundations, retained mastery and evidence that you can apply the skill in real work.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.item});

  final _SkillReadiness item;

  @override
  Widget build(BuildContext context) {
    final stages = const [
      'Learn',
      'Practice',
      'Project',
      'Interview-ready',
    ];
    final activeIndex = stages.indexOf(item.stage);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Chip(label: Text(item.stage)),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var index = 0; index < stages.length; index++)
                  Chip(
                    avatar: Icon(
                      index < activeIndex
                          ? Icons.check_circle
                          : index == activeIndex
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                      size: 17,
                    ),
                    label: Text(stages[index]),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Foundation: ${item.foundationCompleted}/${item.foundationTotal} • '
              'Mastery: ${item.mastery.toStringAsFixed(0)}% • '
              'Evidence: ${item.evidence}',
            ),
            const SizedBox(height: 6),
            Text(
              'Next: ${item.nextAction}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillRadar extends StatelessWidget {
  const _SkillRadar({required this.skills});

  final List<SkillMastery> skills;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return const Center(child: Text('No skill data yet.'));
    }

    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final actual = RadarDataSet(
      dataEntries: [
        for (final skill in skills)
          RadarEntry(value: skill.mastery.clamp(1, 100).toDouble()),
      ],
      fillColor: primary.withAlpha(45),
      borderColor: primary,
      borderWidth: 2,
      entryRadius: 3,
    );

    final ceiling = RadarDataSet(
      dataEntries: [
        for (var index = 0; index < skills.length; index++)
          const RadarEntry(value: 100),
      ],
      fillColor: Colors.transparent,
      borderColor: Colors.transparent,
      borderWidth: 0,
      entryRadius: 0,
    );

    return RadarChart(
      RadarChartData(
        dataSets: [actual, ceiling],
        radarShape: RadarShape.polygon,
        tickCount: 4,
        ticksTextStyle: TextStyle(
          fontSize: 10,
          color: onSurface.withAlpha(150),
        ),
        titleTextStyle: TextStyle(
          fontSize: 12,
          color: onSurface,
        ),
        getTitle: (index, angle) => RadarChartTitle(
          text: skills[index].shortName,
          angle: angle,
        ),
      ),
    );
  }
}
