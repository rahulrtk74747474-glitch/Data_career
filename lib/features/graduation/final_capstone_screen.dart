import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/capstone.dart';
import '../../models/capstone_result.dart';
import '../../services/capstone_scoring_service.dart';
import '../../services/sql_runner.dart';
import '../game/game_providers.dart';

class FinalCapstoneScreen extends ConsumerStatefulWidget {
  const FinalCapstoneScreen({super.key});

  @override
  ConsumerState<FinalCapstoneScreen> createState() =>
      _FinalCapstoneScreenState();
}

class _FinalCapstoneScreenState extends ConsumerState<FinalCapstoneScreen> {
  final _sqlController = TextEditingController();
  final _kpiController = TextEditingController();
  final Set<String> _cleaningSelections = {};
  String _statisticsAnswer = '';
  String _dashboardAnswer = '';
  String _recommendationAnswer = '';
  SqlRunResult? _sqlResult;
  CapstoneScore? _score;
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
    final definition = ref.watch(finalCapstoneProvider);
    final previous = ref.watch(capstoneResultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Final Analyst Capstone')),
      body: SafeArea(
        child: definition.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load final capstone.\n$error'),
          ),
          data: (item) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                item.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(item.context),
              const SizedBox(height: 12),
              previous.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
                data: (result) => result == null
                    ? const SizedBox.shrink()
                    : _PreviousCapstone(result: result),
              ),
              _StepCard(
                number: 1,
                title: 'Validate the data',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.cleaningPrompt),
                    const SizedBox(height: 8),
                    for (final option in item.cleaningOptions)
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
                title: 'Query the portfolio',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.sqlPrompt),
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
                title: 'Interpret the statistics',
                child: _SingleChoice(
                  prompt: item.statisticsPrompt,
                  options: item.statisticsOptions,
                  value: _statisticsAnswer,
                  enabled: _score == null,
                  onChanged: (value) {
                    setState(() => _statisticsAnswer = value);
                  },
                ),
              ),
              _StepCard(
                number: 4,
                title: 'Calculate the KPI',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.kpiPrompt),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _kpiController,
                      enabled: _score == null,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Portfolio KPI answer',
                      ),
                    ),
                  ],
                ),
              ),
              _StepCard(
                number: 5,
                title: 'Design the dashboard view',
                child: _SingleChoice(
                  prompt: item.dashboardPrompt,
                  options: item.dashboardOptions,
                  value: _dashboardAnswer,
                  enabled: _score == null,
                  onChanged: (value) {
                    setState(() => _dashboardAnswer = value);
                  },
                ),
              ),
              _StepCard(
                number: 6,
                title: 'Advise the board',
                child: _SingleChoice(
                  prompt: item.recommendationPrompt,
                  options: item.recommendationOptions,
                  value: _recommendationAnswer,
                  enabled: _score == null,
                  onChanged: (value) {
                    setState(() => _recommendationAnswer = value);
                  },
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _submitting || _score != null
                    ? null
                    : () => _submit(item),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.school_outlined),
                label: const Text('Submit final capstone'),
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
                _CapstoneScoreCard(
                  score: _score!,
                  definition: item,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(CapstoneDefinition definition) async {
    if (_cleaningSelections.isEmpty ||
        _sqlController.text.trim().isEmpty ||
        _statisticsAnswer.isEmpty ||
        _kpiController.text.trim().isEmpty ||
        _dashboardAnswer.isEmpty ||
        _recommendationAnswer.isEmpty) {
      setState(() {
        _feedback = 'Complete all six capstone parts before submitting.';
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

    final score = CapstoneScoringService.score(
      definition: definition,
      cleaningSelections: _cleaningSelections,
      sqlRows: sqlResult.rows,
      statisticsAnswer: _statisticsAnswer,
      kpiAnswer: _kpiController.text,
      dashboardAnswer: _dashboardAnswer,
      recommendationAnswer: _recommendationAnswer,
    );

    await ref.read(capstoneResultRepositoryProvider).save(
          capstoneId: definition.id,
          title: definition.title,
          score: score,
        );

    final mastery = ref.read(masteryRepositoryProvider);
    await mastery.recordAttempt(
      'cleaning',
      CapstoneScoringService.normalizedComponentScore(
        score.cleaning,
        definition.weight('cleaning'),
      ),
    );
    await mastery.recordAttempt(
      'sql',
      CapstoneScoringService.normalizedComponentScore(
        score.sql,
        definition.weight('sql'),
      ),
    );
    await mastery.recordAttempt(
      'statistics',
      CapstoneScoringService.normalizedComponentScore(
        score.statistics,
        definition.weight('statistics'),
      ),
    );
    await mastery.recordAttempt(
      'business',
      CapstoneScoringService.normalizedComponentScore(
        score.kpi + score.dashboard + score.recommendation,
        definition.weight('kpi') +
            definition.weight('dashboard') +
            definition.weight('recommendation'),
      ),
    );

    ref.invalidate(capstoneResultProvider);
    ref.invalidate(skillProfileProvider);
    ref.invalidate(reviewQueueProvider);
    ref.invalidate(portfolioSnapshotProvider);
    ref.invalidate(jobReadinessProvider);
    ref.invalidate(graduationEligibilityProvider);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _sqlResult = sqlResult;
      _score = score;
      _feedback = score.total >= 80
          ? 'Capstone threshold reached. Check Job Readiness for the remaining graduation gates.'
          : 'Capstone saved. Review the missed components and retry after targeted practice.';
    });
  }
}

class _PreviousCapstone extends StatelessWidget {
  const _PreviousCapstone({required this.result});

  final CapstoneResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history_outlined),
        title: Text('Previous capstone: ${result.totalScore}/100'),
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

class _CapstoneScoreCard extends StatelessWidget {
  const _CapstoneScoreCard({
    required this.score,
    required this.definition,
  });

  final CapstoneScore score;
  final CapstoneDefinition definition;

  @override
  Widget build(BuildContext context) {
    final components = [
      ('Cleaning', score.cleaning, definition.weight('cleaning')),
      ('SQL', score.sql, definition.weight('sql')),
      ('Statistics', score.statistics, definition.weight('statistics')),
      ('KPI', score.kpi, definition.weight('kpi')),
      ('Dashboard', score.dashboard, definition.weight('dashboard')),
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
              'Capstone score: ${score.total}/100',
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
