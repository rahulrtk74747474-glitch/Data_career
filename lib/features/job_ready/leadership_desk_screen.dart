import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/job_ready_v15.dart';
import '../game/game_providers.dart';
import 'job_ready_providers.dart';

class LeadershipDeskScreen extends ConsumerWidget {
  const LeadershipDeskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final cases = ref.watch(leadershipCasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leadership Desk')),
      body: SafeArea(
        child: cases.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                'Senior → Lead → Head of Analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Higher levels are about review, prioritization, governance and executive trade-offs—not simply harder queries.',
              ),
              const SizedBox(height: 16),
              for (final item in items)
                _LeadershipTile(
                  item: item,
                  unlocked: progress.careerLevel >= item.minCareerLevel,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadershipTile extends ConsumerWidget {
  const _LeadershipTile({
    required this.item,
    required this.unlocked,
  });

  final LeadershipCase item;
  final bool unlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(gameProgressProvider).rewardedLearningIds
        .contains('decision:leadership:${item.id}');
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: done
              ? const Icon(Icons.check)
              : unlocked
                  ? const Icon(Icons.manage_accounts_outlined)
                  : const Icon(Icons.lock_outline),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${item.level} responsibility${unlocked ? (done ? ' • Completed' : '') : ' • Locked until career level ${item.minCareerLevel}'}',
        ),
        trailing: Icon(
          unlocked ? Icons.chevron_right : Icons.lock,
        ),
        onTap: !unlocked
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _LeadershipCaseScreen(item: item),
                  ),
                ),
      ),
    );
  }
}

class _LeadershipCaseScreen extends ConsumerStatefulWidget {
  const _LeadershipCaseScreen({required this.item});
  final LeadershipCase item;

  @override
  ConsumerState<_LeadershipCaseScreen> createState() =>
      _LeadershipCaseScreenState();
}

class _LeadershipCaseScreenState
    extends ConsumerState<_LeadershipCaseScreen> {
  LeadershipChoice? _choice;

  @override
  Widget build(BuildContext context) {
    final done = ref.watch(gameProgressProvider).rewardedLearningIds
        .contains('decision:leadership:${widget.item.id}');
    return Scaffold(
      appBar: AppBar(title: Text('${widget.item.level} Decision')),
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
                child: Text(widget.item.context),
              ),
            ),
            const SizedBox(height: 12),
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
            FilledButton.icon(
              onPressed: done || _choice == null ? null : _submit,
              icon: const Icon(Icons.gavel_outlined),
              label: Text(done ? 'Decision completed' : 'Make leadership decision'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final choice = _choice!;
    final impact = choice.impact;
    final earned =
        await ref.read(gameProgressProvider.notifier).applyWorkDecision(
              decisionId: 'leadership:${widget.item.id}',
              baseXp: 55,
              score: choice.score,
              trustDelta: impact['trust'] ?? 0,
              dataQualityDelta: impact['dataQuality'] ?? 0,
              riskDelta: impact['risk'] ?? 0,
            );

    await ref.read(taskPerformanceRepositoryProvider).record(
          id: widget.item.id,
          title: 'Leadership: ${widget.item.title}',
          skillKey: 'business',
          difficulty: widget.item.level,
          score: choice.score,
          mode: 'leadership',
          companyKey: ref.read(gameProgressProvider).companyKey,
        );

    ref.invalidate(portfolioSnapshotProvider);
    ref.invalidate(jobReadinessProvider);
    ref.invalidate(achievementsProvider);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${choice.score}/100 leadership decision'),
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
