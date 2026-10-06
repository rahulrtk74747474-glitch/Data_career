import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/narrative_content.dart';
import '../game/game_providers.dart';

class RandomEventsScreen extends ConsumerWidget {
  const RandomEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final events = ref.watch(randomEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Random Analyst Events')),
      body: SafeArea(
        child: events.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load events.\n$error'),
          ),
          data: (items) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Unexpected work happens',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose how you respond to data-quality, priority, governance and privacy incidents. Company metrics move only the first time each event is completed.',
              ),
              const SizedBox(height: 16),
              for (final event in items)
                Card(
                  child: ListTile(
                    leading: Icon(
                      progress.completedEventIds.contains(event.id)
                          ? Icons.check_circle_outline
                          : Icons.bolt_outlined,
                    ),
                    title: Text(event.title),
                    subtitle: Text(event.category),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _RandomEventDetail(event: event),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RandomEventDetail extends ConsumerStatefulWidget {
  const _RandomEventDetail({required this.event});

  final RandomEventDefinition event;

  @override
  ConsumerState<_RandomEventDetail> createState() =>
      _RandomEventDetailState();
}

class _RandomEventDetailState extends ConsumerState<_RandomEventDetail> {
  RandomEventChoice? _choice;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(gameProgressProvider);
    final completed = progress.completedEventIds.contains(widget.event.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.event.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.event.context),
            const SizedBox(height: 16),
            for (final choice in widget.event.choices)
              Card(
                child: ListTile(
                  leading: Icon(
                    _choice == choice
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(choice.text),
                  onTap: completed || _choice != null
                      ? null
                      : () => _choose(choice),
                ),
              ),
            if (_choice != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _choice!.best
                            ? 'Strong response'
                            : 'Learning feedback',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(_choice!.feedback),
                      const SizedBox(height: 8),
                      Text(
                        'Company effect: revenue ${_signed(_choice!.revenueDelta)}, churn ${_signed(_choice!.churnDelta)}, cost ${_signed(_choice!.costDelta)}, satisfaction ${_signed(_choice!.satisfactionDelta)}.',
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (completed)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'This event has already affected your company. Re-open it for review without applying the impact again.',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _choose(RandomEventChoice choice) async {
    await ref.read(gameProgressProvider.notifier).applyRandomEvent(
          eventId: widget.event.id,
          revenueDelta: choice.revenueDelta,
          churnDelta: choice.churnDelta,
          costDelta: choice.costDelta,
          satisfactionDelta: choice.satisfactionDelta,
        );
    final score = choice.best ? 100 : 55;
    await ref.read(masteryRepositoryProvider).recordAttempt(
          'business',
          score,
        );
    await ref.read(taskPerformanceRepositoryProvider).record(
          id: widget.event.id,
          title: widget.event.title,
          skillKey: 'business',
          difficulty: 'Professional',
          score: score,
          mode: 'random_event',
          companyKey: ref.read(gameProgressProvider).companyKey,
        );
    ref.invalidate(skillProfileProvider);
    ref.invalidate(portfolioSnapshotProvider);
    ref.invalidate(jobReadinessProvider);

    if (!mounted) return;
    setState(() => _choice = choice);
  }

  String _signed(double value) =>
      value >= 0 ? '+${value.toStringAsFixed(1)}' : value.toStringAsFixed(1);
}
