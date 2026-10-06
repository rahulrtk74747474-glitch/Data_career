import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_providers.dart';
import '../task/task_screen.dart';

class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(dailyChallengeProvider);
    final progress = ref.watch(gameProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Challenge')),
      body: SafeArea(
        child: challenge.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load today’s challenge.\n$error'),
          ),
          data: (selection) {
            if (selection == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No daily challenge is available at this career stage.'),
                ),
              );
            }

            final completed = progress.completedDaily(selection.dateKey);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  selection.task.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '${selection.dateKey} • ${selection.task.skill} • +${selection.definition.bonusXp} bonus XP',
                ),
                const SizedBox(height: 14),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_fire_department_outlined),
                    title: Text('Daily streak: ${progress.dailyStreak}'),
                    subtitle: Text(
                      completed
                          ? 'Today’s reward is already secured.'
                          : 'Complete one challenge today to extend your streak.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(selection.task.context),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: completed
                      ? null
                      : () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute<void>(
                                  builder: (_) => TaskScreen(
                                    task: selection.task,
                                    dailyChallenge: selection.definition,
                                    dailyDateKey: selection.dateKey,
                                  ),
                                ),
                              )
                              .then((_) {
                            ref.invalidate(dailyChallengeProvider);
                          });
                        },
                  icon: Icon(
                    completed ? Icons.check : Icons.today_outlined,
                  ),
                  label: Text(
                    completed
                        ? 'Completed today'
                        : 'Start today’s challenge',
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
