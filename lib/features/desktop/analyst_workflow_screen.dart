import 'package:flutter/material.dart';

class AnalystWorkflowScreen extends StatefulWidget {
  const AnalystWorkflowScreen({super.key});

  @override
  State<AnalystWorkflowScreen> createState() => _AnalystWorkflowScreenState();
}

class _AnalystWorkflowScreenState extends State<AnalystWorkflowScreen> {
  final _checked = <int>{};

  static const _steps = [
    (
      '1. Understand the request',
      'What decision will this analysis change? Who is the audience? What is the deadline?',
      'Do not start with a chart or query before the decision is clear.'
    ),
    (
      '2. Define metric & grain',
      'Define what one row represents, numerator/denominator, time window and exclusions.',
      'Many “data problems” are actually definition problems.'
    ),
    (
      '3. Inspect & validate data',
      'Check types, nulls, duplicates, ranges, keys, dates and source reconciliation.',
      'A clean-looking result can still come from a broken grain or join.'
    ),
    (
      '4. Analyze',
      'Choose SQL, Excel, Pandas or BI based on the job—not because it is your favorite tool.',
      'Keep the analysis reproducible and as simple as the question allows.'
    ),
    (
      '5. Test assumptions',
      'Check uncertainty, sampling, confounding, outliers, denominators and alternative explanations.',
      'Separate what the data shows from what you think caused it.'
    ),
    (
      '6. Visualize',
      'Choose the chart that fits the decision and data structure; label units and context clearly.',
      'Every visual should earn its space.'
    ),
    (
      '7. Explain',
      'Finding → evidence → bounded interpretation → recommendation → business impact.',
      'If a manager cannot understand it, the analysis is not finished.'
    ),
    (
      '8. Recommend action',
      'Make the next action specific, testable and proportional to the evidence.',
      'Avoid certainty the data cannot support.'
    ),
    (
      '9. Monitor the outcome',
      'Choose the metric and time window that will tell you whether the action worked.',
      'Analytics should close the loop, not end at the presentation.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyst Workflow')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Your analyst operating system',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Use this checklist on every real request until the workflow becomes automatic.',
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < _steps.length; index++)
              Card(
                child: CheckboxListTile(
                  value: _checked.contains(index),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      _checked.add(index);
                    } else {
                      _checked.remove(index);
                    }
                  }),
                  title: Text(
                    _steps[index].$1,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      '${_steps[index].$2}\n\nWatch-out: ${_steps[index].$3}',
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => setState(_checked.clear),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset checklist for a new request'),
            ),
          ],
        ),
      ),
    );
  }
}
