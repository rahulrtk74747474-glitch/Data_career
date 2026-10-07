import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analyst_task.dart';
import '../../models/career_mission.dart';
import '../game/game_providers.dart';
import '../task/task_screen.dart';

class CareerCampaignScreen extends ConsumerWidget {
  const CareerCampaignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missions = ref.watch(careerMissionsProvider);
    final tasks = ref.watch(tasksProvider);
    final progress = ref.watch(gameProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Career Campaign')),
      body: SafeArea(
        child: missions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load career missions.\n$error'),
            ),
          ),
          data: (missionList) => tasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load company tickets.\n$error'),
              ),
            ),
            data: (taskList) {
              final completedCount = missionList
                  .where(
                    (mission) =>
                        progress.rewardedLearningIds.contains(mission.rewardId),
                  )
                  .length;
              final trust =
                  (35 + completedCount * 5).clamp(0, 100).toInt();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Text(
                    'Do the job, not just the lesson',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Each mission connects several analyst tasks into one company problem. Complete the work, report back to your manager and turn it into portfolio evidence.',
                  ),
                  const SizedBox(height: 16),
                  _CampaignSummary(
                    completed: completedCount,
                    total: missionList.length,
                    managerTrust: trust,
                  ),
                  const SizedBox(height: 18),
                  for (var index = 0;
                      index < missionList.length;
                      index++) ...[
                    _MissionCard(
                      mission: missionList[index],
                      previousMission:
                          index == 0 ? null : missionList[index - 1],
                      tasks: taskList,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CampaignSummary extends StatelessWidget {
  const _CampaignSummary({
    required this.completed,
    required this.total,
    required this.managerTrust,
  });

  final int completed;
  final int total;
  final int managerTrust;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$completed / $total projects complete',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  'Trust $managerTrust/100',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 9),
            LinearProgressIndicator(
              value: total == 0 ? 0 : completed / total,
            ),
            const SizedBox(height: 8),
            const Text(
              'Career missions are the bridge from guided learning to Boss Cases and interviews.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends ConsumerWidget {
  const _MissionCard({
    required this.mission,
    required this.previousMission,
    required this.tasks,
  });

  final CareerMission mission;
  final CareerMission? previousMission;
  final List<AnalystTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final completed =
        progress.rewardedLearningIds.contains(mission.rewardId);
    final previousComplete = previousMission == null ||
        progress.rewardedLearningIds.contains(previousMission!.rewardId);
    final chapterUnlocked =
        progress.resolvedCompanyChapter >= mission.companyChapter;
    final unlocked = completed || (previousComplete && chapterUnlocked);
    final completedTickets = mission.taskIds
        .where(progress.completedTaskIds.contains)
        .length;

    String subtitle;
    if (completed) {
      subtitle = 'Project complete • portfolio evidence created';
    } else if (!chapterUnlocked) {
      subtitle =
          'Locked • reach ${mission.companyName} in the company journey';
    } else if (!previousComplete) {
      subtitle = 'Locked • finish the previous career mission';
    } else {
      subtitle =
          '$completedTickets/${mission.taskIds.length} tickets • +${mission.bonusXp} project XP';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          child: completed
              ? const Icon(Icons.check)
              : unlocked
                  ? Text(mission.order.toString())
                  : const Icon(Icons.lock_outline),
        ),
        title: Text(
          mission.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${mission.companyName}\n$subtitle'),
        isThreeLine: true,
        trailing: Icon(
          completed
              ? Icons.workspace_premium_outlined
              : unlocked
                  ? Icons.chevron_right
                  : Icons.lock,
        ),
        onTap: !unlocked
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _MissionDetailScreen(
                      mission: mission,
                      tasks: tasks,
                    ),
                  ),
                ),
      ),
    );
  }
}

class _MissionDetailScreen extends ConsumerWidget {
  const _MissionDetailScreen({
    required this.mission,
    required this.tasks,
  });

  final CareerMission mission;
  final List<AnalystTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final taskMap = {for (final task in tasks) task.id: task};
    final missionTasks = [
      for (final id in mission.taskIds)
        if (taskMap[id] != null) taskMap[id]!,
    ];
    final completed =
        progress.rewardedLearningIds.contains(mission.rewardId);
    final allTicketsDone = mission.taskIds.every(
      progress.completedTaskIds.contains,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Project ${mission.order}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              mission.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(mission.companyName),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            mission.managerName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(mission.briefing),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined, size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(mission.deadlineLabel)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your workday',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Solve each ticket using the real lab. The project is complete only when all required work is finished.',
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < missionTasks.length; index++)
              _MissionTicket(
                number: index + 1,
                task: missionTasks[index],
                completed: progress.completedTaskIds
                    .contains(missionTasks[index].id),
              ),
            if (missionTasks.length != mission.taskIds.length) ...[
              const SizedBox(height: 8),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'One or more referenced tickets could not be loaded. Refresh the app before submitting this project.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (!completed)
              FilledButton.icon(
                onPressed: allTicketsDone &&
                        missionTasks.length == mission.taskIds.length
                    ? () => _submitMission(context, ref)
                    : null,
                icon: const Icon(Icons.send_outlined),
                label: Text(
                  allTicketsDone
                      ? 'Send project to manager (+${mission.bonusXp} XP)'
                      : 'Finish all tickets before reporting back',
                ),
              )
            else
              const _CompletedProjectBanner(),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resume / portfolio evidence',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    SelectableText(mission.resumeBullet),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitMission(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final progress = ref.read(gameProgressProvider);
    if (!mission.taskIds.every(progress.completedTaskIds.contains)) return;

    final earned =
        await ref.read(gameProgressProvider.notifier).awardLearningXp(
              rewardId: mission.rewardId,
              baseXp: mission.bonusXp,
              score: 100,
            );
    await ref.read(taskPerformanceRepositoryProvider).record(
          id: mission.id,
          title: 'Career Project: ${mission.title}',
          skillKey: 'business',
          difficulty: 'Project',
          score: 100,
          mode: 'career_mission',
          companyKey: mission.companyKey,
        );

    ref.invalidate(portfolioSnapshotProvider);
    ref.invalidate(jobReadinessProvider);
    ref.invalidate(skillProfileProvider);
    ref.invalidate(promotionReviewProvider);
    ref.invalidate(companyChapterReviewProvider);

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Manager review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mission.managerFeedback),
            const SizedBox(height: 12),
            Text(
              'Project bonus: +$earned XP',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text('Portfolio evidence added:'),
            const SizedBox(height: 4),
            Text(mission.resumeBullet),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Continue career'),
          ),
        ],
      ),
    );
  }
}

class _MissionTicket extends StatelessWidget {
  const _MissionTicket({
    required this.number,
    required this.task,
    required this.completed,
  });

  final int number;
  final AnalystTask task;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: completed ? const Icon(Icons.check) : Text('$number'),
        ),
        title: Text(task.title),
        subtitle: Text(
          '${task.skill} • ${task.difficulty} • ${task.department}',
        ),
        trailing: Icon(
          completed ? Icons.verified_outlined : Icons.chevron_right,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TaskScreen(task: task),
          ),
        ),
      ),
    );
  }
}

class _CompletedProjectBanner extends StatelessWidget {
  const _CompletedProjectBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.workspace_premium_outlined),
        ),
        title: const Text('Project completed'),
        subtitle: const Text(
          'This mission is now part of your portfolio evidence. Re-open any ticket whenever you want to review the work.',
        ),
      ),
    );
  }
}
