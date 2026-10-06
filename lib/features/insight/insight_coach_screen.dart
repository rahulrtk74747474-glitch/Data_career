import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/narrative_content.dart';
import '../../services/insight_scoring_service.dart';
import '../game/game_providers.dart';

class InsightCoachScreen extends ConsumerWidget {
  const InsightCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = ref.watch(insightScenariosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Insight Coach')),
      body: SafeArea(
        child: scenarios.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load insight scenarios.\n$error'),
          ),
          data: (items) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Write what a manager needs',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Every response is scored on clarity, evidence, recommendation and business impact. The grader is deterministic and works offline.',
              ),
              const SizedBox(height: 16),
              for (final item in items)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.edit_note_outlined),
                    title: Text(item.title),
                    subtitle: Text(
                      '${item.companyKey} • ${item.difficulty}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            _InsightScenarioScreen(scenario: item),
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

class _InsightScenarioScreen extends ConsumerStatefulWidget {
  const _InsightScenarioScreen({required this.scenario});

  final InsightScenario scenario;

  @override
  ConsumerState<_InsightScenarioScreen> createState() =>
      _InsightScenarioScreenState();
}

class _InsightScenarioScreenState
    extends ConsumerState<_InsightScenarioScreen> {
  final _controller = TextEditingController();
  InsightRubricScore? _score;
  ManagerDialogue? _manager;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.scenario;

    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(item.context),
            const SizedBox(height: 14),
            Text(
              item.prompt,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              minLines: 5,
              maxLines: 9,
              decoration: const InputDecoration(
                labelText: 'Your insight',
                hintText:
                    'Finding → evidence → recommendation → business impact',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _grade,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Get manager feedback'),
            ),
            if (_score != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rubric: ${_score!.total}/100',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text('Clarity: ${_score!.clarity}/25'),
                      Text('Evidence: ${_score!.evidence}/30'),
                      Text(
                        'Recommendation: ${_score!.recommendation}/25',
                      ),
                      Text(
                        'Business impact: ${_score!.businessImpact}/20',
                      ),
                      const SizedBox(height: 8),
                      for (final message in _score!.feedback)
                        Text('• $message'),
                    ],
                  ),
                ),
              ),
            ],
            if (_manager != null) ...[
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(_manager!.title),
                  subtitle: Text(_manager!.message),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _grade() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final score = InsightScoringService.score(
      text: text,
      evidenceTerms: widget.scenario.evidenceTerms,
      recommendationTerms: widget.scenario.recommendationTerms,
      impactTerms: widget.scenario.impactTerms,
    );
    final dialogues = await ref.read(managerDialoguesProvider.future);
    final manager = dialogues.firstWhere(
      (item) => score.total >= item.minScore,
      orElse: () => dialogues.last,
    );

    await ref.read(masteryRepositoryProvider).recordAttempt(
          'business',
          score.total,
        );
    await ref.read(taskPerformanceRepositoryProvider).record(
          id: widget.scenario.id,
          title: widget.scenario.title,
          skillKey: 'business',
          difficulty: widget.scenario.difficulty,
          score: score.total,
          mode: 'insight_coach',
          companyKey: widget.scenario.companyKey,
        );
    ref.invalidate(skillProfileProvider);
    ref.invalidate(portfolioSnapshotProvider);
    ref.invalidate(jobReadinessProvider);

    if (!mounted) return;
    setState(() {
      _score = score;
      _manager = manager;
    });
  }
}
