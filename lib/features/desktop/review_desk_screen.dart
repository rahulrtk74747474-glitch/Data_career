import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/workday_content.dart';
import '../game/game_providers.dart';

class ReviewDeskScreen extends ConsumerWidget {
  const ReviewDeskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final cases = ref.watch(reviewDeskCasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review Desk')),
      body: SafeArea(
        child: cases.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                'Review other analysts’ work',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                progress.careerLevel >= 3
                    ? 'Senior responsibility: catch logic, modeling and communication errors before they reach decision-makers.'
                    : 'Preview a Senior Analyst responsibility. Promotion will make this kind of quality review part of your normal work.',
              ),
              const SizedBox(height: 16),
              for (final item in items)
                _ReviewTile(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewTile extends ConsumerWidget {
  const _ReviewTile({required this.item});
  final ReviewDeskCase item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(gameProgressProvider).rewardedLearningIds
        .contains('decision:review:${item.id}');
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: done ? const Icon(Icons.check) : const Icon(Icons.rate_review),
        ),
        title: Text(item.title),
        subtitle: Text(done ? 'Reviewed' : 'Quality-control case'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _ReviewCaseScreen(item: item),
          ),
        ),
      ),
    );
  }
}

class _ReviewCaseScreen extends ConsumerStatefulWidget {
  const _ReviewCaseScreen({required this.item});
  final ReviewDeskCase item;

  @override
  ConsumerState<_ReviewCaseScreen> createState() =>
      _ReviewCaseScreenState();
}

class _ReviewCaseScreenState extends ConsumerState<_ReviewCaseScreen> {
  ScoredWorkChoice? _choice;

  @override
  Widget build(BuildContext context) {
    final done = ref.watch(gameProgressProvider).rewardedLearningIds
        .contains('decision:review:${widget.item.id}');
    return Scaffold(
      appBar: AppBar(title: const Text('Review Analyst Work')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.item.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(widget.item.artifact),
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.item.prompt),
            const SizedBox(height: 8),
            for (final option in widget.item.choices)
              Card(
                child: RadioListTile<ScoredWorkChoice>(
                  value: option,
                  groupValue: _choice,
                  onChanged: done
                      ? null
                      : (value) => setState(() => _choice = value),
                  title: Text(option.text),
                ),
              ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: done || _choice == null ? null : _submit,
              child: Text(done ? 'Reviewed' : 'Send review feedback'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final choice = _choice!;
    final earned =
        await ref.read(gameProgressProvider.notifier).applyWorkDecision(
              decisionId: 'review:${widget.item.id}',
              baseXp: 40,
              score: choice.score,
              trustDelta: choice.score >= 90 ? 2 : choice.score < 50 ? -1 : 0.5,
              dataQualityDelta:
                  choice.score >= 90 ? 2 : choice.score < 50 ? -1 : 0,
              riskDelta: choice.score >= 90 ? -1.5 : choice.score < 50 ? 1.5 : 0,
            );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Review score ${choice.score}/100'),
        content: Text('${choice.feedback}\n\nXP earned: $earned'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
