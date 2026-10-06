import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analyst_task.dart';
import '../../models/skill_mastery.dart';
import '../boss_case/boss_case_screen.dart';
import '../game/game_progress.dart';
import '../game/game_providers.dart';
import '../placement/placement_screen.dart';
import '../practice/practice_gym_screen.dart';
import '../review/review_queue_screen.dart';
import '../skills/skills_screen.dart';
import '../sql_workspace/sql_workspace_screen.dart';
import '../task/task_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final tasks = ref.watch(tasksProvider);
    final placementComplete = ref.watch(placementCompletedProvider);
    final skillProfile = ref.watch(skillProfileProvider);
    final recommendations = ref.watch(adaptiveRecommendationsProvider);
    final reviewQueue = ref.watch(reviewQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DataQuest'),
        actions: [
          IconButton(
            tooltip: 'Skill radar',
            onPressed: () => _open(context, const SkillsScreen()),
            icon: const Icon(Icons.radar),
          ),
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
            ref.invalidate(skillProfileProvider);
            ref.invalidate(placementCompletedProvider);
            ref.invalidate(reviewQueueProvider);
            ref.invalidate(adaptiveRecommendationsProvider);
            await Future.wait([
              ref.read(tasksProvider.future),
              ref.read(skillProfileProvider.future),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CareerCard(progress: progress),
              const SizedBox(height: 12),
              placementComplete.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => const SizedBox.shrink(),
                data: (complete) => _PlacementCard(
                  complete: complete,
                  onPlacement: () =>
                      _open(context, const PlacementScreen()),
                  onSkills: () => _open(context, const SkillsScreen()),
                ),
              ),
              const SizedBox(height: 12),
              skillProfile.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
                data: (skills) => _SkillSummaryCard(skills: skills),
              ),
              const SizedBox(height: 16),
              _FeatureGrid(
                reviewCount: reviewQueue.valueOrNull?.length ?? 0,
                onGym: () => _open(context, const PracticeGymScreen()),
                onReview: () =>
                    _open(context, const ReviewQueueScreen()),
                onWorkspace: () =>
                    _open(context, const SqlWorkspaceScreen()),
                onBoss: () => _open(context, const BossCaseScreen()),
              ),
              recommendations.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
                data: (items) => items.isEmpty
                    ? const SizedBox.shrink()
                    : _Recommendations(
                        tasks: items,
                        onOpen: (task) => _open(
                          context,
                          TaskScreen(task: task),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
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
                        completed:
                            progress.completedTaskIds.contains(task.id),
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
                      'Could not load the offline task packs.\n$error',
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

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset career progress?'),
          content: const Text(
            'This removes completed tickets, XP, placement results, skill mastery and Boss Case scores stored on this device.',
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
      await ref.read(masteryRepositoryProvider).resetAll();
      await ref.read(bossCaseResultRepositoryProvider).resetAll();
      ref.invalidate(skillProfileProvider);
      ref.invalidate(placementCompletedProvider);
      ref.invalidate(reviewQueueProvider);
      ref.invalidate(adaptiveRecommendationsProvider);
    }
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({
    required this.reviewCount,
    required this.onGym,
    required this.onReview,
    required this.onWorkspace,
    required this.onBoss,
  });

  final int reviewCount;
  final VoidCallback onGym;
  final VoidCallback onReview;
  final VoidCallback onWorkspace;
  final VoidCallback onBoss;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Practice Gym', 'Skills + difficulty', Icons.fitness_center, onGym),
      (
        'Review Queue',
        reviewCount == 0
            ? 'Nothing due'
            : '$reviewCount priority reviews',
        Icons.replay,
        onReview,
      ),
      ('SQL Workstation', 'Schemas + scratchpad', Icons.storage, onWorkspace),
      ('Boss Case', 'End-to-end case', Icons.emoji_events_outlined, onBoss),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.55,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: InkWell(
            onTap: item.$4,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.$3),
                  const SizedBox(height: 8),
                  Text(
                    item.$1,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(item.$2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Recommendations extends StatelessWidget {
  const _Recommendations({
    required this.tasks,
    required this.onOpen,
  });

  final List<AnalystTask> tasks;
  final ValueChanged<AnalystTask> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended for you',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text('Chosen from your weakest unfinished skills.'),
          const SizedBox(height: 8),
          for (final task in tasks.take(2))
            Card(
              child: ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: Text(task.title),
                subtitle:
                    Text('${task.skill} • ${task.difficulty}'),
                onTap: () => onOpen(task),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlacementCard extends StatelessWidget {
  const _PlacementCard({
    required this.complete,
    required this.onPlacement,
    required this.onSkills,
  });

  final bool complete;
  final VoidCallback onPlacement;
  final VoidCallback onSkills;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          complete ? Icons.verified_outlined : Icons.fact_check_outlined,
        ),
        title: Text(
          complete ? 'Placement test completed' : 'Take the placement test',
        ),
        subtitle: Text(
          complete
              ? 'Your starting mastery is saved offline.'
              : '5 questions • about 3 minutes • no pass/fail',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: complete ? onSkills : onPlacement,
      ),
    );
  }
}

class _SkillSummaryCard extends StatelessWidget {
  const _SkillSummaryCard({required this.skills});

  final List<SkillMastery> skills;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return const SizedBox.shrink();

    final sorted = [...skills]
      ..sort((a, b) => a.mastery.compareTo(b.mastery));
    final weakest = sorted.first;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.psychology_alt_outlined),
        title: const Text('Adaptive learning'),
        subtitle: Text(
          'Weakest now: ${weakest.displayName} (${weakest.mastery.toStringAsFixed(0)}%).',
        ),
      ),
    );
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
        subtitle: Text(
          '${task.department} • ${task.skill} • ${task.difficulty} • ${task.xp} XP',
        ),
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
