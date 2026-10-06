import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/boss_case.dart';
import '../../models/boss_case_result.dart';
import '../../services/boss_case_scoring_service.dart';
import '../../services/sql_runner.dart';
import '../game/game_providers.dart';

class BossCaseScreen extends ConsumerStatefulWidget {
  const BossCaseScreen({super.key});

  @override
  ConsumerState<BossCaseScreen> createState() => _BossCaseScreenState();
}

class _BossCaseScreenState extends ConsumerState<BossCaseScreen> {
  final _sqlController = TextEditingController();
  final _kpiController = TextEditingController();
  final Set<String> _cleaningSelections = {};
  String _chartAnswer = '';
  String _recommendationAnswer = '';
  SqlRunResult? _sqlResult;
  BossCaseScore? _score;
  String? _feedback;
  bool _submitting = false;

  @override
  void dispose() {
    _sqlController.dispose();
    _kpiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final definition = ref.watch(bossCaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Boss Case')),
      body: SafeArea(
        child: definition.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load the Boss Case.\n$error'),
          ),
          data: (caseDefinition) {
            final previous =
                ref.watch(bossCaseResultProvider(caseDefinition.id));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  caseDefinition.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(caseDefinition.company),
                const SizedBox(height: 12),
                Text(caseDefinition.context),
                const SizedBox(height: 12),
                previous.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                  data: (result) => result == null
                      ? const SizedBox.shrink()
                      : _PreviousResult(result: result),
                ),
                _StepCard(
                  number: 1,
                  title: 'Clean the data',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(caseDefinition.cleaningPrompt),
                      const SizedBox(height: 8),
                      for (final option in caseDefinition.cleaningOptions)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _cleaningSelections.contains(option),
                          title: Text(option),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: _score != null
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value ?? false) {
                                      _cleaningSelections.add(option);
                                    } else {
                                      _cleaningSelections.remove(option);
                                    }
                                  });
                                },
                        ),
                    ],
                  ),
                ),
                _StepCard(
                  number: 2,
                  title: 'Query the business',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(caseDefinition.sqlPrompt),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _sqlController,
                        minLines: 6,
                        maxLines: 12,
                        enabled: _score == null,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          hintText: 'SELECT ...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_sqlResult != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _sqlResult!.isSuccess
                              ? 'SQLite returned ${_sqlResult!.rows.length} rows.'
                              : (_sqlResult!.error ?? 'SQL error'),
                        ),
                      ],
                    ],
                  ),
                ),
                _StepCard(
                  number: 3,
                  title: 'Calculate the KPI',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(caseDefinition.kpiPrompt),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _kpiController,
                        enabled: _score == null,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Your KPI answer',
                          suffixText: '%',
                        ),
                      ),
                    ],
                  ),
                ),
                _StepCard(
                  number: 4,
                  title: 'Choose the chart',
                  child: _SingleChoice(
                    prompt: caseDefinition.chartPrompt,
                    options: caseDefinition.chartOptions,
                    value: _chartAnswer,
                    enabled: _score == null,
                    onChanged: (value) {
                      setState(() => _chartAnswer = value);
                    },
                  ),
                ),
                _StepCard(
                  number: 5,
                  title: 'Advise the executive',
                  child: _SingleChoice(
                    prompt: caseDefinition.recommendationPrompt,
                    options: caseDefinition.recommendationOptions,
                    value: _recommendationAnswer,
                    enabled: _score == null,
                    onChanged: (value) {
                      setState(() => _recommendationAnswer = value);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _submitting || _score != null
                      ? null
                      : () => _submit(caseDefinition),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.emoji_events_outlined),
                  label: const Text('Submit Boss Case'),
                ),
                if (_feedback != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(_feedback!),
                    ),
                  ),
                ],
                if (_score != null) ...[
                  const SizedBox(height: 12),
                  _ScoreCard(
                    score: _score!,
                    definition: caseDefinition,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit(BossCaseDefinition definition) async {
    if (_cleaningSelections.isEmpty ||
        _sqlController.text.trim().isEmpty ||
        _kpiController.text.trim().isEmpty ||
        _chartAnswer.isEmpty ||
        _recommendationAnswer.isEmpty) {
      setState(() {
        _feedback = 'Complete all five parts before submitting.';
      });
      return;
    }

    setState(() => _submitting = true);
    final sqlResult =
        await ref.read(sqlRunnerProvider).runReadOnly(_sqlController.text);

    if (!sqlResult.isSuccess) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _sqlResult = sqlResult;
        _feedback = sqlResult.error;
      });
      return;
    }

    final score = BossCaseScoringService.score(
      definition: definition,
      cleaningSelections: _cleaningSelections,
      sqlRows: sqlResult.rows,
      kpiAnswer: _kpiController.text,
      chartAnswer: _chartAnswer,
      recommendationAnswer: _recommendationAnswer,
    );

    await ref
        .read(bossCaseResultRepositoryProvider)
        .save(definition.id, score);

    final mastery = ref.read(masteryRepositoryProvider);
    await mastery.recordAttempt(
      'cleaning',
      BossCaseScoringService.normalizedComponentScore(
        score.cleaning,
        definition.weight('cleaning'),
      ),
    );
    await mastery.recordAttempt(
      'sql',
      BossCaseScoringService.normalizedComponentScore(
        score.sql,
        definition.weight('sql'),
      ),
    );
    await mastery.recordAttempt(
      'statistics',
      BossCaseScoringService.normalizedComponentScore(
        score.kpi,
        definition.weight('kpi'),
      ),
    );
    await mastery.recordAttempt(
      'business',
      BossCaseScoringService.normalizedComponentScore(
        score.chart + score.recommendation,
        definition.weight('chart') + definition.weight('recommendation'),
      ),
    );

    ref.invalidate(skillProfileProvider);
    ref.invalidate(reviewQueueProvider);
    ref.invalidate(bossCaseResultProvider(definition.id));
    ref.invalidate(portfolioSnapshotProvider);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _sqlResult = sqlResult;
      _score = score;
      _feedback = score.total >= 70
          ? 'Boss Case complete. Strong analyst-level performance.'
          : 'Boss Case complete. Review the weak components and retry from the Practice Gym before your next case.';
    });
  }
}

class _PreviousResult extends StatelessWidget {
  const _PreviousResult({required this.result});

  final BossCaseResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text('Previous score: ${result.totalScore}/100'),
        subtitle: Text(
          'Saved ${result.completedAt.toLocal().toString().split('.').first}',
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.title,
    required this.child,
  });

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step $number • $title',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _SingleChoice extends StatelessWidget {
  const _SingleChoice({
    required this.prompt,
    required this.options,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String prompt;
  final List<String> options;
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt),
        const SizedBox(height: 6),
        for (final option in options)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: Icon(
                value == option
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(option),
              selected: value == option,
              onTap: enabled ? () => onChanged(option) : null,
            ),
          ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.score,
    required this.definition,
  });

  final BossCaseScore score;
  final BossCaseDefinition definition;

  @override
  Widget build(BuildContext context) {
    final components = [
      ('Cleaning', score.cleaning, definition.weight('cleaning')),
      ('SQL', score.sql, definition.weight('sql')),
      ('KPI', score.kpi, definition.weight('kpi')),
      ('Chart', score.chart, definition.weight('chart')),
      (
        'Recommendation',
        score.recommendation,
        definition.weight('recommendation'),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Boss score: ${score.total}/100',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            for (final component in components)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${component.$1}: ${component.$2}/${component.$3}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
