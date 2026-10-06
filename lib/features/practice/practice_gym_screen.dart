import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analyst_task.dart';
import '../game/game_providers.dart';
import '../task/task_screen.dart';

class PracticeGymScreen extends ConsumerStatefulWidget {
  const PracticeGymScreen({super.key});

  @override
  ConsumerState<PracticeGymScreen> createState() =>
      _PracticeGymScreenState();
}

class _PracticeGymScreenState extends ConsumerState<PracticeGymScreen> {
  String _difficulty = 'All';

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Gym')),
      body: SafeArea(
        child: tasks.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load practice tasks.\n$error'),
          ),
          data: (items) {
            final filtered = _difficulty == 'All'
                ? items
                : items
                    .where((task) => task.difficulty == _difficulty)
                    .toList();
            final skillNames = <String>{
              for (final task in filtered) task.skill,
            }.toList()
              ..sort();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Train by skill',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Repeat tickets freely. Difficulty and mastery are separate: practice improves mastery after every successful attempt.',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final level in const [
                      'All',
                      'Beginner',
                      'Intermediate',
                      'Advanced',
                    ])
                      ChoiceChip(
                        label: Text(level),
                        selected: _difficulty == level,
                        onSelected: (_) {
                          setState(() => _difficulty = level);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No tasks at this difficulty yet.'),
                    ),
                  ),
                for (final skill in skillNames) ...[
                  Text(
                    skill,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  for (final task
                      in filtered.where((item) => item.skill == skill))
                    _PracticeTaskCard(task: task),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PracticeTaskCard extends StatelessWidget {
  const _PracticeTaskCard({required this.task});

  final AnalystTask task;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(task.title),
        subtitle: Text(
          '${task.difficulty} • ${task.department} • ${task.xp} XP first completion',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TaskScreen(
                task: task,
                reviewMode: true,
              ),
            ),
          );
        },
      ),
    );
  }
}
