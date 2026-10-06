import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/adaptive_review_service.dart';
import '../game/game_providers.dart';
import '../task/task_screen.dart';

class ReviewQueueScreen extends ConsumerWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(reviewQueueProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Review Queue')),
      body: SafeArea(
        child: queue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not build the review queue.\n$error'),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No reviews are due yet. Complete the placement test and some tickets; weak or due skills will appear here automatically.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Highest priority first',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Due topics come first; within the same urgency, lower mastery gets priority.',
                ),
                const SizedBox(height: 16),
                for (var index = 0; index < items.length; index++)
                  _ReviewCard(
                    rank: index + 1,
                    item: items[index],
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TaskScreen(
                            task: items[index].task,
                            reviewMode: true,
                          ),
                        ),
                      );
                      ref.invalidate(skillProfileProvider);
                      ref.invalidate(reviewQueueProvider);
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.rank,
    required this.item,
    required this.onTap,
  });

  final int rank;
  final ReviewItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(rank.toString())),
        title: Text(item.task.title),
        subtitle: Text(
          item.skill.displayName + ' • ' + item.reason,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
