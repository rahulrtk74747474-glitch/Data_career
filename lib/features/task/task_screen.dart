import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analyst_task.dart';
import '../../services/scoring_service.dart';
import '../game/game_providers.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({
    super.key,
    required this.task,
  });

  final AnalystTask task;

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  final _answerController = TextEditingController();
  int _revealedHints = 0;
  int _failedAttempts = 0;
  String? _feedback;
  bool _solved = false;

  AnalystTask get task => widget.task;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(gameProgressProvider);
    final alreadyCompleted = progress.completedTaskIds.contains(task.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(task.department),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              task.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text('${task.skill} • Up to ${task.xp} XP'),
            const SizedBox(height: 18),
            _InfoBlock(
              title: 'Business context',
              body: task.context,
              icon: Icons.business_center_outlined,
            ),
            _InfoBlock(
              title: 'Goal',
              body: task.goal,
              icon: Icons.flag_outlined,
            ),
            _InfoBlock(
              title: 'Deliverable',
              body: task.deliverable,
              icon: Icons.task_alt,
            ),
            if (task.rows.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.datasetName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _DatasetPreview(rows: task.rows),
            ],
            const SizedBox(height: 20),
            Text(
              task.prompt,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (task.answerType == 'choice')
              _ChoiceAnswer(
                options: task.options,
                value: _answerController.text,
                onChanged: (value) {
                  setState(() {
                    _answerController.text = value;
                    _feedback = null;
                  });
                },
              )
            else
              TextField(
                controller: _answerController,
                minLines: task.answerType == 'sql_tokens' ? 5 : 1,
                maxLines: task.answerType == 'sql_tokens' ? 10 : 3,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: task.answerType == 'formula'
                      ? 'Your spreadsheet formula'
                      : 'Your SQL query',
                  hintText: task.answerType == 'formula'
                      ? '=...'
                      : 'SELECT ...',
                  alignLabelWithHint: true,
                ),
                onChanged: (_) {
                  if (_feedback != null) {
                    setState(() => _feedback = null);
                  }
                },
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: alreadyCompleted || _solved ? null : _submit,
              icon: const Icon(Icons.play_arrow),
              label: Text(
                alreadyCompleted
                    ? 'Already completed'
                    : _solved
                        ? 'Completed'
                        : 'Submit analysis',
              ),
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
            const SizedBox(height: 18),
            _HintPanel(
              hints: task.hints,
              revealedHints: _revealedHints,
              onReveal: _revealedHints < task.hints.length && !_solved
                  ? () => setState(() => _revealedHints++)
                  : null,
            ),
            if (_solved || alreadyCompleted) ...[
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why this works',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(task.explanation),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final result = ScoringService.grade(task, _answerController.text);

    if (!result.isCorrect) {
      setState(() {
        _failedAttempts++;
        _feedback = result.feedback;
      });
      return;
    }

    final score = (100 - (_revealedHints * 15) - (_failedAttempts * 10))
        .clamp(40, 100)
        .toInt();

    await ref.read(gameProgressProvider.notifier).completeTask(
          task,
          score: score,
        );

    if (!mounted) return;
    setState(() {
      _solved = true;
      _feedback =
          '${result.feedback}\nScore: $score/100. XP and company metrics updated.';
    });
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatasetPreview extends StatelessWidget {
  const _DatasetPreview({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final columns = rows.first.keys.toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            for (final column in columns) DataColumn(label: Text(column)),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  for (final column in columns)
                    DataCell(Text('${row[column] ?? ''}')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceAnswer extends StatelessWidget {
  const _ChoiceAnswer({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              onTap: () => onChanged(option),
            ),
          ),
      ],
    );
  }
}

class _HintPanel extends StatelessWidget {
  const _HintPanel({
    required this.hints,
    required this.revealedHints,
    required this.onReveal,
  });

  final List<String> hints;
  final int revealedHints;
  final VoidCallback? onReveal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hints',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Hints get more specific. Using them reduces the score, but learning is more important than guessing.',
            ),
            for (var index = 0; index < revealedHints; index++) ...[
              const SizedBox(height: 10),
              Text('Hint ${index + 1}: ${hints[index]}'),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onReveal,
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(
                revealedHints == 0
                    ? 'Reveal hint 1'
                    : revealedHints < hints.length
                        ? 'Reveal hint ${revealedHints + 1}'
                        : 'All hints revealed',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
