import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analyst_task.dart';
import '../game/game_progress.dart';
import '../game/game_providers.dart';
import '../task/task_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final tasks = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DataQuest'),
        actions: [
          IconButton(
            tooltip: 'Reset progress',
            onPressed: () => _confirmReset(context, ref),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tasksProvider);
            await ref.read(tasksProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CareerCard(progress: progress),
              const SizedBox(height: 16),
              Text(
                'Company pulse',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _MetricGrid(progress: progress),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Today’s tickets',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text('${progress.completedTaskIds.length} completed'),
                ],
              ),
              const SizedBox(height: 8),
              tasks.when(
                data: (items) => Column(
                  children: [
                    for (final task in items)
                      _TaskCard(
                        task: task,
                        completed: progress.completedTaskIds.contains(task.id),
                      ),
                  ],
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Could not load the offline task pack.\n$error',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset career progress?'),
          content: const Text(
            'This removes completed tickets and XP stored on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      await ref.read(gameProgressProvider.notifier).reset();
    }
  }
}

class _CareerCard extends StatelessWidget {
  const _CareerCard({required this.progress});

  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E-commerce Co. • Week 1',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(
              progress.role,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress.roleProgress),
            const SizedBox(height: 8),
            Text(
              progress.xp >= 2000
                  ? '${progress.xp} XP • Top career level reached'
                  : '${progress.xp} / ${progress.nextRoleXp} XP to next role',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.progress});

  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    final metrics = <({String label, String value, IconData icon})>[
      (
        label: 'Revenue index',
        value: progress.revenueIndex.toStringAsFixed(1),
        icon: Icons.trending_up,
      ),
      (
        label: 'Churn',
        value: '${progress.churnRate.toStringAsFixed(1)}%',
        icon: Icons.person_remove_alt_1,
      ),
      (
        label: 'Cost index',
        value: progress.costIndex.toStringAsFixed(1),
        icon: Icons.payments_outlined,
      ),
      (
        label: 'Satisfaction',
        value: '${progress.satisfaction.toStringAsFixed(0)}%',
        icon: Icons.sentiment_satisfied_alt,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(metric.icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(metric.label),
                      Text(
                        metric.value,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.completed,
  });

  final AnalystTask task;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: completed
              ? const Icon(Icons.check)
              : Text(task.department.substring(0, 1)),
        ),
        title: Text(task.title),
        subtitle: Text('${task.department} • ${task.skill} • ${task.xp} XP'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TaskScreen(task: task),
            ),
          );
        },
      ),
    );
  }
}
