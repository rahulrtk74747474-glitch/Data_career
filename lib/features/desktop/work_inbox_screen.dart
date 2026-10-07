import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/workday_content.dart';
import '../game/game_providers.dart';

class WorkInboxScreen extends ConsumerWidget {
  const WorkInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final messages = ref.watch(workInboxMessagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Work Inbox')),
      body: SafeArea(
        child: messages.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (items) {
            final visible = items.where((item) {
              final company = item.companyKey == 'general' ||
                  item.companyKey == progress.companyKey;
              return company && item.minCareerLevel <= progress.careerLevel;
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  'Messages waiting for an analyst decision',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'These are deliberately vague, urgent or misleading requests. Your response affects company metrics and manager trust.',
                ),
                const SizedBox(height: 16),
                for (final item in visible)
                  _InboxTile(message: item),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InboxTile extends ConsumerWidget {
  const _InboxTile({required this.message});
  final WorkInboxMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final done = progress.rewardedLearningIds
        .contains('decision:inbox:${message.id}');

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: done
              ? const Icon(Icons.done)
              : const Icon(Icons.mail_outline),
        ),
        title: Text(
          message.subject,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${message.sender} • ${message.senderRole} • ${message.urgency}'
          '${done ? ' • Responded' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _InboxDetail(message: message),
          ),
        ),
      ),
    );
  }
}

class _InboxDetail extends ConsumerStatefulWidget {
  const _InboxDetail({required this.message});
  final WorkInboxMessage message;

  @override
  ConsumerState<_InboxDetail> createState() => _InboxDetailState();
}

class _InboxDetailState extends ConsumerState<_InboxDetail> {
  ScoredWorkChoice? _choice;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(gameProgressProvider);
    final done = progress.rewardedLearningIds
        .contains('decision:inbox:${widget.message.id}');

    return Scaffold(
      appBar: AppBar(title: const Text('Message')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.message.subject,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text('${widget.message.sender} • ${widget.message.senderRole}'),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(widget.message.body),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              done ? 'Response already sent' : 'How do you respond?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final option in widget.message.choices)
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
            FilledButton.icon(
              onPressed: done || _choice == null ? null : _send,
              icon: const Icon(Icons.send_outlined),
              label: Text(done ? 'Already responded' : 'Send response'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final choice = _choice!;
    final impact = choice.impact;
    final earned =
        await ref.read(gameProgressProvider.notifier).applyWorkDecision(
              decisionId: 'inbox:${widget.message.id}',
              baseXp: 30,
              score: choice.score,
              revenueDelta: impact['revenue'] ?? 0,
              churnDelta: impact['churn'] ?? 0,
              costDelta: impact['cost'] ?? 0,
              satisfactionDelta: impact['satisfaction'] ?? 0,
              trustDelta: impact['trust'] ?? 0,
              dataQualityDelta: impact['dataQuality'] ?? 0,
              riskDelta: impact['risk'] ?? 0,
            );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Decision score: ${choice.score}/100'),
        content: SingleChildScrollView(
          child: Text(
            '${choice.feedback}'
            '${choice.followUp.isEmpty ? '' : '\n\n${choice.followUp}'}'
            '\n\nXP earned: $earned\n'
            'Company consequences have been applied.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Back to work'),
          ),
        ],
      ),
    );
  }
}
