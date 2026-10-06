import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_providers.dart';

class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  final Map<String, String> _answers = {};
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(placementQuestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Placement Test')),
      body: SafeArea(
        child: questions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load the placement test.\n$error'),
            ),
          ),
          data: (items) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Find your starting level',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Five short questions cover spreadsheets, SQL, cleaning, statistics and business reasoning. This is diagnostic, not pass/fail.',
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < items.length; index++) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${index + 1} • ${items[index].skillKey}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          items[index].question,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final option in items[index].options)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              _answers[items[index].id] == option
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                            ),
                            title: Text(option),
                            selected: _answers[items[index].id] == option,
                            onTap: _submitting
                                ? null
                                : () {
                                    setState(() {
                                      _answers[items[index].id] = option;
                                    });
                                  },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              FilledButton.icon(
                onPressed: _submitting
                    ? null
                    : () => _submit(items.length),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Score placement test'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(int questionCount) async {
    final questions = await ref.read(placementQuestionsProvider.future);
    if (_answers.length != questionCount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answer all five questions before scoring.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final skillScores = <String, int>{};
    var correctCount = 0;
    for (final question in questions) {
      final correct = _answers[question.id] == question.correctOption;
      if (correct) correctCount++;
      skillScores[question.skillKey] = correct ? 80 : 30;
    }

    await ref.read(masteryRepositoryProvider).applyPlacement(skillScores);
    ref.invalidate(skillProfileProvider);
    ref.invalidate(placementCompletedProvider);

    if (!mounted) return;
    setState(() => _submitting = false);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Placement complete'),
          content: Text(
            'You answered $correctCount of $questionCount correctly. Your skill radar is now initialized, and weaker topics will return sooner for review.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (mounted) Navigator.pop(context);
  }
}
