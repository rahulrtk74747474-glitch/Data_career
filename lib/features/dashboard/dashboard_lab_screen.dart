import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dashboard_challenge.dart';
import '../../services/dashboard_scoring_service.dart';
import '../../widgets/solution_reveal_card.dart';
import '../game/game_providers.dart';

class DashboardLabScreen extends ConsumerWidget {
  const DashboardLabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(dashboardChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Decision Lab')),
      body: SafeArea(
        child: challenges.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load dashboard challenges.\n$error'),
          ),
          data: (items) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Design for decisions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Practice KPI definition, chart choice, dashboard hierarchy and visual critique—the work that turns analysis into management decisions.',
              ),
              const SizedBox(height: 16),
              for (final challenge in items)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.dashboard_outlined),
                    title: Text(challenge.title),
                    subtitle: Text(
                      '${challenge.category} • ${challenge.difficulty}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _DashboardChallengeScreen(
                            challenge: challenge,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardChallengeScreen extends ConsumerStatefulWidget {
  const _DashboardChallengeScreen({required this.challenge});

  final DashboardChallenge challenge;

  @override
  ConsumerState<_DashboardChallengeScreen> createState() =>
      _DashboardChallengeScreenState();
}

class _DashboardChallengeScreenState
    extends ConsumerState<_DashboardChallengeScreen> {
  String _answer = '';
  int _hints = 0;
  int _failed = 0;
  String? _feedback;
  bool _completed = false;
  bool _solutionViewed = false;

  DashboardChallenge get challenge => widget.challenge;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(challenge.category)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              challenge.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(challenge.context),
            const SizedBox(height: 16),
            Text(
              challenge.prompt,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final option in challenge.options)
              Card(
                child: ListTile(
                  leading: Icon(
                    _answer == option
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(option),
                  selected: _answer == option,
                  onTap: _completed
                      ? null
                      : () {
                          setState(() {
                            _answer = option;
                            _feedback = null;
                          });
                        },
                ),
              ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _completed ? null : _submit,
              child: const Text('Submit dashboard decision'),
            ),
            if (_feedback != null) ...[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(_feedback!),
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _hints < challenge.hints.length && !_completed
                  ? () => setState(() => _hints++)
                  : null,
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(
                _hints < challenge.hints.length
                    ? 'Reveal hint ${_hints + 1}'
                    : 'All hints revealed',
              ),
            ),
            for (var index = 0; index < _hints; index++)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Hint ${index + 1}: ${challenge.hints[index]}',
                ),
              ),
            const SizedBox(height: 12),
            SolutionRevealCard(
              solution: challenge.solutionText,
              revealed: _solutionViewed,
              penaltyApplies: !_completed,
              onReveal: _solutionViewed
                  ? null
                  : () => setState(() => _solutionViewed = true),
            ),
            if (_completed) ...[
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Design explanation\n\n${challenge.explanation}',
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
    final grade = DashboardScoringService.grade(challenge, _answer);
    if (!grade.isCorrect) {
      setState(() {
        _failed++;
        _feedback = grade.feedback;
      });
      return;
    }

    final score =
        (100 - (_hints * 15) - (_failed * 10)).clamp(40, 100).toInt();
    final earnedXp =
        await ref.read(gameProgressProvider.notifier).awardLearningXp(
              rewardId: 'dashboard:${challenge.id}',
              baseXp: challenge.xp,
              score: score,
              solutionViewed: _solutionViewed,
            );
    await ref.read(masteryRepositoryProvider).recordAttempt('business', score);
    await ref.read(taskPerformanceRepositoryProvider).record(
          id: challenge.id,
          title: challenge.title,
          skillKey: 'business',
          difficulty: challenge.difficulty,
          score: score,
        );
    ref.invalidate(skillProfileProvider);
    ref.invalidate(portfolioSnapshotProvider);

    if (!mounted) return;
    setState(() {
      _completed = true;
      _feedback =
          '${grade.feedback}\nScore: $score/100. XP earned: $earnedXp. Business mastery and portfolio evidence updated.${_solutionViewed ? '\nSolution viewed: 5 XP deducted from this task reward.' : ''}';
    });
  }
}
