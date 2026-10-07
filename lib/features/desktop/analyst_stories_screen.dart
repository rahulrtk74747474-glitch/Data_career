import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_providers.dart';

class AnalystStoriesScreen extends ConsumerWidget {
  const AnalystStoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(analystStoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Analyst Stories')),
      body: SafeArea(
        child: stories.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                'Short business stories worth remembering',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Synthetic scenarios based on common analytics failure patterns—not proprietary company data.',
              ),
              const SizedBox(height: 16),
              for (final story in items)
                Card(
                  child: ExpansionTile(
                    title: Text(
                      story.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(story.companyKey.toUpperCase()),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _StoryPart(label: 'Setup', text: story.setup),
                      _StoryPart(
                        label: 'Turning point',
                        text: story.turningPoint,
                      ),
                      _StoryPart(label: 'Analyst lesson', text: story.lesson),
                      const SizedBox(height: 8),
                      for (final takeaway in story.takeaways)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.check_circle_outline),
                          title: Text(takeaway),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryPart extends StatelessWidget {
  const _StoryPart({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('$label\n$text'),
      ),
    );
  }
}
