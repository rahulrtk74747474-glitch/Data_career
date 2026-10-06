import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_providers.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Badges & Achievements')),
      body: SafeArea(
        child: badges.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load achievements.\n$error'),
          ),
          data: (items) {
            final unlocked = items.where((item) => item.unlocked).length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '$unlocked / ${items.length} badges unlocked',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Badges summarize evidence already earned; they do not replace task scores or portfolio history.',
                ),
                const SizedBox(height: 16),
                for (final badge in items)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          badge.unlocked
                              ? Icons.emoji_events
                              : Icons.lock_outline,
                        ),
                      ),
                      title: Text(badge.title),
                      subtitle: Text(badge.description),
                      trailing: badge.unlocked
                          ? const Icon(Icons.check_circle)
                          : null,
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
