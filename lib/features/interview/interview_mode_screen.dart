import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/interview.dart';
import '../../models/interview_result.dart';
import '../game/game_providers.dart';
import 'interview_session_screen.dart';

class InterviewModeScreen extends ConsumerWidget {
  const InterviewModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rounds = ref.watch(availableInterviewRoundsProvider);
    final results = ref.watch(interviewResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Interview Mode')),
      body: SafeArea(
        child: rounds.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load interview rounds.\n$error'),
          ),
          data: (items) {
            final saved = <String, InterviewResult>{
              for (final result
                  in results.valueOrNull ?? const <InterviewResult>[])
                result.roundKey: result,
            };

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Practice the hiring loop',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'SQL uses the real offline database. Case and behavioral answers use visible professional rubrics. Choose timed simulation or untimed practice.',
                ),
                const SizedBox(height: 16),
                for (final round in items)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            round.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(round.description),
                          if (saved[round.key] != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Best: ${saved[round.key]!.bestScore}/100 • '
                              '${saved[round.key]!.attempts} attempts',
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _openSession(
                                  context,
                                  round,
                                  timed: false,
                                ),
                                icon: const Icon(Icons.school_outlined),
                                label: const Text('Untimed'),
                              ),
                              FilledButton.icon(
                                onPressed: () => _openSession(
                                  context,
                                  round,
                                  timed: true,
                                ),
                                icon: const Icon(Icons.timer_outlined),
                                label: Text(
                                  'Timed ${(round.durationSeconds / 60).ceil()}m',
                                ),
                              ),
                            ],
                          ),
                        ],
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

  void _openSession(
    BuildContext context,
    InterviewRoundDefinition round, {
    required bool timed,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InterviewSessionScreen(
          round: round,
          timed: timed,
        ),
      ),
    );
  }
}
