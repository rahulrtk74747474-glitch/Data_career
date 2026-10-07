import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analytics_challenge.dart';
import '../../services/analytics_scoring_service.dart';
import '../../widgets/solution_reveal_card.dart';
import '../game/game_providers.dart';

class AnalyticsStudioScreen extends ConsumerStatefulWidget {
  const AnalyticsStudioScreen({super.key});

  @override
  ConsumerState<AnalyticsStudioScreen> createState() =>
      _AnalyticsStudioScreenState();
}

class _AnalyticsStudioScreenState
    extends ConsumerState<AnalyticsStudioScreen> {
  String _mode = 'all';

  @override
  Widget build(BuildContext context) {
    final challenges = ref.watch(analyticsChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Studio')),
      body: SafeArea(
        child: challenges.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load Analytics Studio.\n$error'),
          ),
          data: (items) {
            final filtered = _mode == 'all'
                ? items
                : items.where((item) => item.mode == _mode).toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Statistics + dashboard reasoning',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose the statistically defensible interpretation or build the right chart/KPI set, then write the insight an analyst would actually send to a manager.',
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All')),
                    ButtonSegment(
                      value: 'statistics',
                      label: Text('Statistics'),
                    ),
                    ButtonSegment(
                      value: 'dashboard',
                      label: Text('Dashboard'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (value) {
                    setState(() => _mode = value.first);
                  },
                ),
                const SizedBox(height: 16),
                for (final item in filtered)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        item.isDashboard
                            ? Icons.dashboard_outlined
                            : Icons.functions,
                      ),
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.mode == 'statistics' ? 'Statistics' : 'Dashboard/KPI'} • ${item.difficulty} • ${item.companyKey}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              _AnalyticsChallengeScreen(challenge: item),
                        ),
                      ),
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

class _AnalyticsChallengeScreen extends ConsumerStatefulWidget {
  const _AnalyticsChallengeScreen({required this.challenge});

  final AnalyticsChallenge challenge;

  @override
  ConsumerState<_AnalyticsChallengeScreen> createState() =>
      _AnalyticsChallengeScreenState();
}

class _AnalyticsChallengeScreenState
    extends ConsumerState<_AnalyticsChallengeScreen> {
  final _insightController = TextEditingController();
  String _answer = '';
  String _chart = '';
  final Set<String> _kpis = {};
  int _revealedHints = 0;
  AnalyticsScore? _score;
  bool _solved = false;
  bool _solutionViewed = false;
  int _earnedXp = 0;

  @override
  void dispose() {
    _insightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.challenge;

    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${item.mode == 'statistics' ? 'Statistics' : 'Dashboard/KPI'} • ${item.difficulty}',
            ),
            const SizedBox(height: 10),
            Text(item.context),
            const SizedBox(height: 16),
            Text(
              item.prompt,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (!item.isDashboard)
              for (final option in item.options)
                Card(
                  child: ListTile(
                    leading: Icon(
                      _answer == option
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: Text(option),
                    selected: _answer == option,
                    onTap: _solved
                        ? null
                        : () => setState(() => _answer = option),
                  ),
                )
            else ...[
              Text(
                'Chart choice',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final option in item.chartOptions)
                Card(
                  child: ListTile(
                    leading: Icon(
                      _chart == option
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: Text(option),
                    selected: _chart == option,
                    onTap: _solved
                        ? null
                        : () => setState(() => _chart = option),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                'KPI builder',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final kpi in item.kpiOptions)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(kpi),
                  value: _kpis.contains(kpi),
                  onChanged: _solved
                      ? null
                      : (value) {
                          setState(() {
                            if (value ?? false) {
                              _kpis.add(kpi);
                            } else {
                              _kpis.remove(kpi);
                            }
                          });
                        },
                ),
            ],
            const SizedBox(height: 14),
            Text(
              item.insightPrompt,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _insightController,
              enabled: !_solved,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Write your insight',
                hintText:
                    'Finding → evidence → recommendation → business impact',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _solved ? null : _submit,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Grade analysis'),
            ),
            if (_score != null) ...[
              const SizedBox(height: 12),
              _ScoreCard(score: _score!),
            ],
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3-level hints',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    for (var i = 0; i < _revealedHints; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('${i + 1}. ${item.hints[i]}'),
                      ),
                    OutlinedButton.icon(
                      onPressed: _solved ||
                              _revealedHints >= item.hints.length
                          ? null
                          : () => setState(() => _revealedHints++),
                      icon: const Icon(Icons.lightbulb_outline),
                      label: Text(
                        _revealedHints >= item.hints.length
                            ? 'All hints revealed'
                            : 'Reveal hint ${_revealedHints + 1}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SolutionRevealCard(
              solution: item.solutionText,
              revealed: _solutionViewed,
              penaltyApplies: !_solved,
              onReveal: _solutionViewed
                  ? null
                  : () => setState(() => _solutionViewed = true),
            ),
            if (_earnedXp > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('XP earned: $_earnedXp'),
              ),
            if (_solved) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why this works',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(item.explanation),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final item = widget.challenge;
    if (_insightController.text.trim().isEmpty ||
        (!item.isDashboard && _answer.isEmpty) ||
        (item.isDashboard && (_chart.isEmpty || _kpis.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the technical choice and written insight.'),
        ),
      );
      return;
    }

    final result = AnalyticsScoringService.score(
      challenge: item,
      answer: _answer,
      chart: _chart,
      kpis: _kpis,
      insightText: _insightController.text,
    );

    final earnedXp =
        await ref.read(gameProgressProvider.notifier).awardLearningXp(
              rewardId: 'analytics:${item.id}',
              baseXp: item.xp,
              score: result.total,
              solutionViewed: _solutionViewed,
            );
    await ref.read(masteryRepositoryProvider).recordAttempt(
          item.skillKey,
          result.total,
        );
    await ref.read(taskPerformanceRepositoryProvider).record(
          id: item.id,
          title: item.title,
          skillKey: item.skillKey,
          difficulty: item.difficulty,
          score: result.total,
          mode: 'analytics_studio',
          companyKey: item.companyKey,
        );

    ref.invalidate(skillProfileProvider);
    ref.invalidate(reviewQueueProvider);
    ref.invalidate(portfolioSnapshotProvider);
    ref.invalidate(jobReadinessProvider);

    if (!mounted) return;
    setState(() {
      _score = result;
      _solved = result.total >= 70;
      _earnedXp = earnedXp;
    });
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});

  final AnalyticsScore score;

  @override
  Widget build(BuildContext context) {
    final rubric = score.insight;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score: ${score.total}/100',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Technical: ${score.technical}/50'),
            Text('Clarity: ${rubric.clarity}/25'),
            Text('Evidence: ${rubric.evidence}/30'),
            Text('Recommendation: ${rubric.recommendation}/25'),
            Text('Business impact: ${rubric.businessImpact}/20'),
            const SizedBox(height: 8),
            for (final message in score.feedback)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $message'),
              ),
          ],
        ),
      ),
    );
  }
}
