import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/portfolio_snapshot.dart';
import '../../services/portfolio_service.dart';
import '../game/game_providers.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(portfolioSnapshotProvider);
    final skills = ref.watch(skillProfileProvider);
    final progress = ref.watch(gameProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio Evidence')),
      body: SafeArea(
        child: snapshot.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load portfolio evidence.\n$error'),
          ),
          data: (portfolio) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Evidence, not just badges',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Your strongest completed tickets, labs and Boss Cases are saved locally and can be exported as a text summary for a resume, application or interview-prep document.',
              ),
              const SizedBox(height: 16),
              _PortfolioMetrics(snapshot: portfolio),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final skillData =
                      skills.valueOrNull ?? const [];
                  final summary = PortfolioService.buildSummary(
                    snapshot: portfolio,
                    role: progress.role,
                    xp: progress.xp,
                    skills: skillData,
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
                label: const Text('Copy portfolio summary'),
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
            ],
          ),
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
              label: 'Avg best',
              value: '${snapshot.averageBestScore.toStringAsFixed(0)}%',
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
