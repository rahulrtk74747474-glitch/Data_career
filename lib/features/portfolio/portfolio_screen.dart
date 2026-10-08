import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/portfolio_snapshot.dart';
import '../../models/skill_mastery.dart';
import '../../services/career_artifact_service.dart';
import '../../services/portfolio_service.dart';
import '../game/game_providers.dart';
import '../job_ready/job_ready_providers.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(portfolioSnapshotProvider);
    final skills = ref.watch(skillProfileProvider);
    final progress = ref.watch(gameProgressProvider);
    final missions = ref.watch(careerMissionsProvider);
    final flagshipWorkdays = ref.watch(flagshipWorkdaysProvider);
    final flagshipAttempts = ref.watch(flagshipAttemptsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio Evidence')),
      body: SafeArea(
        child: snapshot.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load portfolio evidence.\n$error'),
          ),
          data: (portfolio) {
            final completedMissions = (missions.valueOrNull ?? const [])
                .where(
                  (mission) =>
                      progress.rewardedLearningIds.contains(mission.rewardId),
                )
                .toList();
            final workdays = flagshipWorkdays.valueOrNull ?? const [];
            final savedFlagships = flagshipAttempts.valueOrNull ?? const {};
            final completedFlagships = workdays
                .where((item) => savedFlagships[item.id]?.isComplete ?? false)
                .toList();
            final projectHighlights = [
              for (final mission in completedMissions)
                mission.resumeBullet,
              for (final workday in completedFlagships)
                workday.resumeBullet,
            ];
            return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Evidence, not just badges',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Best-score summaries are paired with an append-only attempt timeline. Generate a local HTML report, open it on-device, share it, or use the browser Print → Save as PDF flow.',
              ),
              const SizedBox(height: 16),
              _PortfolioMetrics(snapshot: portfolio),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final skillData =
                          skills.valueOrNull ?? const <SkillMastery>[];
                      final summary = PortfolioService.buildSummary(
                        snapshot: portfolio,
                        role: progress.role,
                        xp: progress.xp,
                        skills: skillData,
                        companyName: progress.companyName,
                      );
                      await Clipboard.setData(ClipboardData(text: summary));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Portfolio summary copied to clipboard.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copy summary'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final skillData =
                          skills.valueOrNull ?? const <SkillMastery>[];
                      try {
                        final exportResult = await ref
                            .read(portfolioExportServiceProvider)
                            .exportHtml(
                              snapshot: portfolio,
                              role: progress.role,
                              companyName: progress.companyName,
                              xp: progress.xp,
                              skills: skillData,
                              projectHighlights: projectHighlights,
                            );
                        final openResult = await ref
                            .read(portfolioDeliveryServiceProvider)
                            .open(exportResult.path);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                openResult.opened
                                    ? 'Portfolio opened with your device file/browser app.'
                                    : 'Could not open report: ${openResult.message}',
                              ),
                            ),
                          );
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not open portfolio report: $error',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.open_in_new_outlined),
                    label: const Text('Open report'),
                  ),
                  Builder(
                    builder: (buttonContext) => FilledButton.icon(
                      onPressed: () async {
                        final skillData =
                            skills.valueOrNull ?? const <SkillMastery>[];
                        final box =
                            buttonContext.findRenderObject() as RenderBox?;
                        final origin = box == null
                            ? null
                            : box.localToGlobal(Offset.zero) & box.size;
                        try {
                          final exportResult = await ref
                              .read(portfolioPdfExportServiceProvider)
                              .exportPdf(
                                snapshot: portfolio,
                                role: progress.role,
                                companyName: progress.companyName,
                                xp: progress.xp,
                                skills: skillData,
                                projectHighlights: projectHighlights,
                              );
                          final shareResult = await ref
                              .read(portfolioDeliveryServiceProvider)
                              .share(
                                exportResult.path,
                                sharePositionOrigin: origin,
                                title: 'DataQuest Analyst Portfolio PDF',
                                text:
                                    'DataQuest analyst portfolio PDF generated from synthetic training evidence.',
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Share result: ${shareResult.status.name}.',
                                ),
                              ),
                            );
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not share portfolio report: $error',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share PDF'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (completedMissions.isNotEmpty) ...[
                Text(
                  'Career project highlights',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Resume-ready statements from completed multi-skill company projects.',
                ),
                const SizedBox(height: 8),
                for (final mission in completedMissions)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.work_history_outlined),
                      title: Text(mission.title),
                      subtitle: SelectableText(mission.resumeBullet),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
              if (completedFlagships.isNotEmpty) ...[
                Text(
                  'Flagship portfolio projects',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'End-to-end Day-at-Work projects with open-ended analysis and manager communication.',
                ),
                const SizedBox(height: 8),
                for (final workday in completedFlagships)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.workspace_premium_outlined),
                      title: Text(workday.title),
                      subtitle: SelectableText(workday.resumeBullet),
                      trailing: Text(
                        '${savedFlagships[workday.id]!.totalScore}/100',
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
              _ProjectCards(
                cards: CareerArtifactService.buildProjectCards(portfolio),
              ),
              const SizedBox(height: 20),
              Text(
                'Strongest ticket and lab evidence',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (portfolio.taskPerformances.isEmpty)
                const Text(
                  'Complete a ticket, Pandas challenge, or dashboard challenge to add evidence.',
                )
              else
                for (final item in portfolio.taskPerformances)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(item.bestScore.toString()),
                      ),
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.skillKey} • ${item.difficulty} • ${item.attempts} attempts',
                      ),
                    ),
                  ),
              const SizedBox(height: 18),
              Text(
                'Boss Cases',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (portfolio.bossCases.isEmpty)
                const Text('No Boss Case evidence yet.')
              else
                for (final result in portfolio.bossCases)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.emoji_events_outlined),
                      title: Text(result.caseId),
                      subtitle: Text(
                        'Cleaning ${result.cleaningScore} • SQL ${result.sqlScore} • KPI ${result.kpiScore} • Chart ${result.chartScore} • Recommendation ${result.recommendationScore}',
                      ),
                      trailing: Text('${result.totalScore}/100'),
                    ),
                  ),
              const SizedBox(height: 18),
              Text(
                'Immutable attempt history',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (portfolio.attempts.isEmpty)
                const Text('No recorded attempts yet.')
              else
                for (final attempt in portfolio.attempts.take(30))
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.history_outlined),
                      title: Text(attempt.title),
                      subtitle: Text(
                        '${attempt.sourceType} • ${attempt.mode} • ${attempt.companyKey}\n'
                        '${attempt.completedAt.toLocal().toString().split('.').first}',
                      ),
                      isThreeLine: true,
                      trailing: Text('${attempt.score}/100'),
                    ),
                  ),
            ],
          );
          },
        ),
      ),
    );
  }
}

class _PortfolioMetrics extends StatelessWidget {
  const _PortfolioMetrics({required this.snapshot});

  final PortfolioSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final strongest = snapshot.strongestTask;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _Metric(
              label: 'Evidence',
              value: snapshot.evidenceCount.toString(),
            ),
            _Metric(
              label: 'Attempts',
              value: snapshot.attemptCount.toString(),
            ),
            _Metric(
              label: 'Avg attempt',
              value: '${snapshot.averageAttemptScore.toStringAsFixed(0)}%',
            ),
            _Metric(
              label: 'Strongest',
              value: strongest == null
                  ? '—'
                  : '${strongest.bestScore}/100',
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}


class _ProjectCards extends StatelessWidget {
  const _ProjectCards({required this.cards});

  final List<PortfolioProjectCard> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portfolio projects',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'Case-study cards built from your strongest recorded Boss Case and capstone evidence.',
        ),
        const SizedBox(height: 8),
        for (final card in cards)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('${card.company} • ${card.score}/100 • ${card.attempts} attempts'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final skill in card.skills)
                        Chip(label: Text(skill)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
