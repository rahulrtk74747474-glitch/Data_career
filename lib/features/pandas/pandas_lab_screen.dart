import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/pandas_challenge.dart';
import '../../services/pandas_simulator.dart';
import '../../widgets/solution_reveal_card.dart';
import '../game/game_providers.dart';

class PandasLabScreen extends ConsumerWidget {
  const PandasLabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(pandasChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Python / Pandas Lab')),
      body: SafeArea(
        child: challenges.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load Pandas challenges.\n$error'),
          ),
          data: (items) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Guided dataframe simulator',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Write real Pandas-style expressions. DataQuest validates the operation pattern and simulates the dataframe result locally without bundling a Python runtime.',
              ),
              const SizedBox(height: 16),
              for (final difficulty in const [
                'Beginner',
                'Intermediate',
                'Advanced',
              ]) ...[
                Text(
                  difficulty,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final item in items.where(
                  (challenge) => challenge.difficulty == difficulty,
                ))
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.code),
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.datasetName} • ${item.xp} practice XP',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _PandasChallengeScreen(
                              challenge: item,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PandasChallengeScreen extends ConsumerStatefulWidget {
  const _PandasChallengeScreen({required this.challenge});

  final PandasChallenge challenge;

  @override
  ConsumerState<_PandasChallengeScreen> createState() =>
      _PandasChallengeScreenState();
}

class _PandasChallengeScreenState
    extends ConsumerState<_PandasChallengeScreen> {
  final _controller = TextEditingController();
  int _hints = 0;
  int _failed = 0;
  PandasRunResult? _result;
  bool _completed = false;
  bool _solutionViewed = false;

  PandasChallenge get challenge => widget.challenge;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(challenge.difficulty)),
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
            const SizedBox(height: 14),
            Text(
              challenge.datasetName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _RowsTable(rows: challenge.rows),
            const SizedBox(height: 16),
            Text(
              challenge.prompt,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              enabled: !_completed,
              minLines: 5,
              maxLines: 10,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Pandas expression',
                hintText: "df[...]",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _completed ? null : _run,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run simulated dataframe'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(_result!.feedback),
                ),
              ),
              if (_result!.rows.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Dataframe result',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _RowsTable(rows: _result!.rows),
              ],
            ],
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hints',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (var index = 0; index < _hints; index++) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Hint ${index + 1}: ${challenge.hints[index]}',
                      ),
                    ],
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed:
                          _hints < challenge.hints.length && !_completed
                              ? () => setState(() => _hints++)
                              : null,
                      child: Text(
                        _hints < challenge.hints.length
                            ? 'Reveal hint ${_hints + 1}'
                            : 'All hints revealed',
                      ),
                    ),
                  ],
                ),
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
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Why this works\n\n${challenge.explanation}',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _run() async {
    final result = PandasSimulator.run(challenge, _controller.text);
    if (!result.isCorrect) {
      setState(() {
        _failed++;
        _result = result;
      });
      return;
    }

    final score =
        (100 - (_hints * 15) - (_failed * 10)).clamp(40, 100).toInt();
    final earnedXp =
        await ref.read(gameProgressProvider.notifier).awardLearningXp(
              rewardId: 'pandas:${challenge.id}',
              baseXp: challenge.xp,
              score: score,
              solutionViewed: _solutionViewed,
            );
    await ref.read(masteryRepositoryProvider).recordAttempt('python', score);
    await ref.read(taskPerformanceRepositoryProvider).record(
          id: challenge.id,
          title: challenge.title,
          skillKey: 'python',
          difficulty: challenge.difficulty,
          score: score,
        );
    ref.invalidate(skillProfileProvider);
    ref.invalidate(reviewQueueProvider);
    ref.invalidate(portfolioSnapshotProvider);

    if (!mounted) return;
    setState(() {
      _completed = true;
      _result = PandasRunResult(
        isCorrect: true,
        feedback:
            '${result.feedback}\nScore: $score/100. XP earned: $earnedXp. Python/Pandas mastery and portfolio evidence updated.${_solutionViewed ? '\nSolution viewed: 5 XP deducted from this task reward.' : ''}',
        rows: result.rows,
      );
    });
  }
}

class _RowsTable extends StatelessWidget {
  const _RowsTable({required this.rows});

  final List<Map<String, Object?>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('No rows.');
    final columns = rows.first.keys.toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            for (final column in columns) DataColumn(label: Text(column)),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  for (final column in columns)
                    DataCell(Text((row[column] ?? 'NULL').toString())),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
