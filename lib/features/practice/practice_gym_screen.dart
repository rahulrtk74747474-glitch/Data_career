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
  String _skill = 'All';

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
            final allSkills = <String>{
              for (final task in items) task.skill,
            }.toList()
              ..sort();

            final filtered = items.where((task) {
              final difficultyMatches =
                  _difficulty == 'All' || task.difficulty == _difficulty;
              final skillMatches =
                  _skill == 'All' || task.skill == _skill;
              return difficultyMatches && skillMatches;
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Train by skill and difficulty',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Repeat tickets freely. Successful practice updates mastery and your strongest portfolio score without awarding duplicate career XP.',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _skill,
                  decoration: const InputDecoration(
                    labelText: 'Skill',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'All',
                      child: Text('All skills'),
                    ),
                    for (final skill in allSkills)
                      DropdownMenuItem(
                        value: skill,
                        child: Text(skill),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _skill = value);
                    }
                  },
                ),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No tasks match these filters yet.',
                      ),
                    ),
                  ),
                for (final task in filtered)
                  _PracticeTaskCard(task: task),
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
          '${task.skill} • ${task.difficulty} • ${task.xp} XP first completion',
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
