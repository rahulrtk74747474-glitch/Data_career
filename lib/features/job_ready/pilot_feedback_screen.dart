import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_providers.dart';

class PilotFeedbackScreen extends ConsumerStatefulWidget {
  const PilotFeedbackScreen({super.key});

  @override
  ConsumerState<PilotFeedbackScreen> createState() =>
      _PilotFeedbackScreenState();
}

class _PilotFeedbackScreenState extends ConsumerState<PilotFeedbackScreen> {
  final _confusionController = TextEditingController();
  final _freeTextController = TextEditingController();
  int _realism = 4;
  int _usefulness = 4;
  String _wouldPay = 'Maybe';
  bool _saving = false;

  @override
  void dispose() {
    _confusionController.dispose();
    _freeTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(learningHealthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Beta Learning Health')),
      body: SafeArea(
        child: report.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (item) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                'Measure the product, not just the feature count',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'All metrics below are stored locally. A beta tester can submit feedback without sending learning data to an external analytics service.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Metric(label: 'App opens', value: '${item.appOpens}'),
                  _Metric(label: 'Active days', value: '${item.activeDays}'),
                  _Metric(
                    label: 'D1 retained',
                    value: _retention(item.d1Retained),
                  ),
                  _Metric(
                    label: 'D7 retained',
                    value: _retention(item.d7Retained),
                  ),
                  _Metric(
                    label: 'Workdays started',
                    value: '${item.workdayStarts}',
                  ),
                  _Metric(
                    label: 'Workdays finished',
                    value: '${item.workdayCompletions}',
                  ),
                  _Metric(
                    label: 'Feedback forms',
                    value: '${item.feedbackCount}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Workday stage completion funnel (local)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final stage in const [
                    'quality', 'tool', 'analysis',
                    'statistics', 'chart', 'manager',
                  ])
                    _Metric(
                      label: stage,
                      value: '${item.stageCompletions[stage] ?? 0}',
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Beta feedback',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              _Rating(
                label: 'How realistic does the analyst job feel?',
                value: _realism,
                onChanged: (value) => setState(() => _realism = value),
              ),
              _Rating(
                label: 'How useful is DataQuest for becoming job-ready?',
                value: _usefulness,
                onChanged: (value) => setState(() => _usefulness = value),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confusionController,
                decoration: const InputDecoration(
                  labelText: 'Where did you feel confused or want to quit?',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              const Text('Would you pay for the full career simulation?'),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Yes', label: Text('Yes')),
                  ButtonSegment(value: 'Maybe', label: Text('Maybe')),
                  ButtonSegment(value: 'No', label: Text('No')),
                ],
                selected: {_wouldPay},
                onSelectionChanged: (value) {
                  setState(() => _wouldPay = value.first);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _freeTextController,
                decoration: const InputDecoration(
                  labelText: 'What would make you use it every week?',
                  border: OutlineInputBorder(),
                ),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save beta feedback locally'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showExport(context),
                icon: const Icon(Icons.data_object),
                label: const Text('Preview local beta JSON'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(learningTelemetryServiceProvider).saveFeedback(
          realism: _realism,
          usefulness: _usefulness,
          confusion: _confusionController.text,
          wouldPay: _wouldPay,
          freeText: _freeTextController.text,
        );
    ref.invalidate(learningHealthProvider);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback saved on this device.')),
    );
  }

  Future<void> _showExport(BuildContext context) async {
    final json = await ref.read(learningTelemetryServiceProvider).exportJson();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Local beta data'),
        content: SingleChildScrollView(
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(json),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static String _retention(bool? value) =>
      value == null ? 'Pending' : value ? 'Yes' : 'No';
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _Rating extends StatelessWidget {
  const _Rating({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            Slider(
              min: 1,
              max: 5,
              divisions: 4,
              label: '$value/5',
              value: value.toDouble(),
              onChanged: (next) => onChanged(next.round()),
            ),
          ],
        ),
      ),
    );
  }
}
