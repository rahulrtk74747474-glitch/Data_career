import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/career_artifact_service.dart';
import '../game/game_providers.dart';

class ResumeBuilderScreen extends ConsumerStatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  ConsumerState<ResumeBuilderScreen> createState() =>
      _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends ConsumerState<ResumeBuilderScreen> {
  bool _seeded = false;
  final List<String> _drafts = [];

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(portfolioSnapshotProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Resume Bullet Builder')),
      body: SafeArea(
        child: snapshot.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load evidence.\n$error'),
          ),
          data: (portfolio) {
            if (!_seeded) {
              _drafts
                ..clear()
                ..addAll(
                  CareerArtifactService.buildResumeBullets(portfolio)
                      .map((item) => item.text),
                );
              _seeded = true;
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Turn verified practice into honest resume language',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Every suggestion is based on your recorded DataQuest evidence. Edit the wording for your resume, but do not convert synthetic training results into claims about real employer impact.',
                ),
                const SizedBox(height: 16),
                if (_drafts.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Complete tickets, Boss Cases or the final capstone to generate evidence-backed bullets.',
                      ),
                    ),
                  )
                else
                  for (var index = 0; index < _drafts.length; index++)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextFormField(
                          key: ValueKey('resume-bullet-$index'),
                          initialValue: _drafts[index],
                          minLines: 2,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: 'Bullet ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) => _drafts[index] = value,
                        ),
                      ),
                    ),
                if (_drafts.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      final text = _drafts
                          .where((item) => item.trim().isNotEmpty)
                          .map((item) => '• ${item.trim()}')
                          .join('\n');
                      await Clipboard.setData(ClipboardData(text: text));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edited resume bullets copied.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copy edited bullets'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
