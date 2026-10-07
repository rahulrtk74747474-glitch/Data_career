import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/workday_content.dart';
import '../game/game_providers.dart';

class MetricRelationshipLabScreen extends ConsumerWidget {
  const MetricRelationshipLabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(metricRelationshipCasesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Metric Relationship Lab')),
      body: SafeArea(
        child: cases.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                'Learn how metrics move together',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'A single KPI can mislead. These cases train you to read growth, profitability, retention, cost and risk as one system.',
              ),
              const SizedBox(height: 16),
              for (final item in items)
                _CaseTile(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaseTile extends ConsumerWidget {
  const _CaseTile({required this.item});
  final MetricRelationshipCase item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(gameProgressProvider).rewardedLearningIds
        .contains('decision:metric:${item.id}');
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: done ? const Icon(Icons.check) : const Icon(Icons.hub_outlined),
        ),
        title: Text(item.title),
        subtitle: Text('${item.metrics.length} connected metrics'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _MetricCaseScreen(item: item),
          ),
        ),
      ),
    );
  }
}

class _MetricCaseScreen extends ConsumerStatefulWidget {
  const _MetricCaseScreen({required this.item});
  final MetricRelationshipCase item;

  @override
  ConsumerState<_MetricCaseScreen> createState() =>
      _MetricCaseScreenState();
}

class _MetricCaseScreenState extends ConsumerState<_MetricCaseScreen> {
  ScoredWorkChoice? _choice;

  @override
  Widget build(BuildContext context) {
    final done = ref.watch(gameProgressProvider).rewardedLearningIds
        .contains('decision:metric:${widget.item.id}');

    return Scaffold(
      appBar: AppBar(title: const Text('Metric Case')),
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
            const SizedBox(height: 14),
            for (final entry in widget.item.metrics.entries)
              Card(
                child: ListTile(
                  title: Text(entry.key),
                  trailing: Text(
                    entry.value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              widget.item.prompt,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final option in widget.item.choices)
              Card(
                child: ListTile(
                  leading: Icon(
                    identical(_choice, option)
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(option.text),
                  selected: identical(_choice, option),
                  onTap: done
                      ? null
                      : () => setState(() => _choice = option),
                ),
              ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: done || _choice == null ? null : _submit,
              child: Text(done ? 'Completed' : 'Submit interpretation'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final choice = _choice!;
    final trust = choice.score >= 90
        ? 1.5
        : choice.score >= 60
            ? 0.3
            : -1.5;
    final earned =
        await ref.read(gameProgressProvider.notifier).applyWorkDecision(
              decisionId: 'metric:${widget.item.id}',
              baseXp: 35,
              score: choice.score,
              trustDelta: trust,
              dataQualityDelta: choice.score >= 90 ? 1 : 0,
              riskDelta: choice.score >= 90 ? -1 : choice.score < 50 ? 1 : 0,
            );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Score ${choice.score}/100'),
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
