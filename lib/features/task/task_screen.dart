import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analyst_task.dart';
import '../../models/daily_challenge.dart';
import '../../services/scoring_service.dart';
import '../../services/sql_editor_helper.dart';
import '../../services/sql_result_grader.dart';
import '../../widgets/solution_reveal_card.dart';
import '../game/game_providers.dart';
import '../sql_workspace/sql_workspace_screen.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({
    super.key,
    required this.task,
    this.reviewMode = false,
    this.dailyChallenge,
    this.dailyDateKey,
  });

  final AnalystTask task;
  final bool reviewMode;
  final DailyChallengeDefinition? dailyChallenge;
  final String? dailyDateKey;

  bool get isDaily => dailyChallenge != null && dailyDateKey != null;

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  final _answerController = TextEditingController();
  final Set<String> _selectedOptions = {};
  int _revealedHints = 0;
  int _failedAttempts = 0;
  String? _feedback;
  bool _solved = false;
  bool _submitting = false;
  bool _solutionViewed = false;
  List<String> _sqlColumns = const [];
  List<Map<String, Object?>> _sqlRows = const [];

  AnalystTask get task => widget.task;
  bool get _isSql => task.answerType == 'sql_result';

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(gameProgressProvider);
    final alreadyCompleted = widget.isDaily
        ? progress.completedDaily(widget.dailyDateKey!)
        : !widget.reviewMode && progress.completedTaskIds.contains(task.id);

    final title = widget.isDaily
        ? 'Daily Challenge'
        : widget.reviewMode
            ? 'Practice Review'
            : task.department;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${task.skill} • ${task.difficulty} • Up to ${task.xp} XP',
            ),
            if (widget.isDaily) ...[
              const SizedBox(height: 4),
              Text('Daily bonus: +${widget.dailyChallenge!.bonusXp} XP'),
            ],
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
            Text(task.prompt, style: Theme.of(context).textTheme.titleMedium),
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
            else if (task.answerType == 'multi_select')
              _MultiSelectAnswer(
                options: task.options,
                selected: _selectedOptions,
                onChanged: (option, selected) {
                  setState(() {
                    if (selected) {
                      _selectedOptions.add(option);
                    } else {
                      _selectedOptions.remove(option);
                    }
                    _feedback = null;
                  });
                },
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isSql) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'SQL keyword shortcuts',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SqlWorkspaceScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.table_view_outlined),
                          label: const Text('Schema & scratchpad'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final keyword in SqlEditorHelper.keywords)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(keyword.trim()),
                                onPressed: () => _insertSqlKeyword(keyword),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: _answerController,
                    minLines: _isSql ? 5 : 1,
                    maxLines: _isSql ? 12 : 3,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType:
                        _isSql ? TextInputType.multiline : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: task.answerType == 'formula'
                          ? 'Your spreadsheet formula'
                          : 'Your SQL query',
                      hintText:
                          task.answerType == 'formula' ? '=...' : 'SELECT ...',
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      if (_feedback != null) {
                        setState(() => _feedback = null);
                      }
                    },
                  ),
                ],
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  alreadyCompleted || _solved || _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                alreadyCompleted
                    ? 'Already completed'
                    : _solved
                        ? 'Completed'
                        : _isSql
                            ? 'Run SQL & grade'
                            : widget.isDaily
                                ? 'Submit daily challenge'
                                : widget.reviewMode
                                    ? 'Submit review'
                                    : 'Submit analysis',
              ),
            ),
            if (_sqlRows.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'SQLite result',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _SqlResultTable(columns: _sqlColumns, rows: _sqlRows),
            ],
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
            const SizedBox(height: 12),
            SolutionRevealCard(
              solution: task.solutionText,
              revealed: _solutionViewed,
              penaltyApplies: !alreadyCompleted && !_solved,
              onReveal: _solutionViewed
                  ? null
                  : () => setState(() => _solutionViewed = true),
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

  void _insertSqlKeyword(String keyword) {
    _answerController.value = SqlEditorHelper.insertKeyword(
      _answerController.value,
      keyword,
    );
    if (_feedback != null) {
      setState(() => _feedback = null);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    GradeResult grade;
    if (_isSql) {
      final run =
          await ref.read(sqlRunnerProvider).runReadOnly(_answerController.text);
      if (!run.isSuccess) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _failedAttempts++;
          _feedback = run.error;
          _sqlRows = const [];
          _sqlColumns = const [];
        });
        return;
      }

      final result = SqlResultGrader.grade(
        actualRows: run.rows,
        expectedRows: task.expectedRows,
      );
      grade = GradeResult(
        isCorrect: result.isCorrect,
        feedback: result.feedback,
      );

      if (mounted) {
        setState(() {
          _sqlRows = run.rows;
          _sqlColumns = run.columns;
        });
      }
    } else if (task.answerType == 'multi_select') {
      grade = ScoringService.gradeSelections(task, _selectedOptions);
    } else {
      grade = ScoringService.grade(task, _answerController.text);
    }

    if (!grade.isCorrect) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _failedAttempts++;
        _feedback = grade.feedback;
      });
      return;
    }

    final score = (100 - (_revealedHints * 15) - (_failedAttempts * 10))
        .clamp(40, 100)
        .toInt();

    if (widget.isDaily) {
      await ref.read(gameProgressProvider.notifier).completeDailyChallenge(
            dateKey: widget.dailyDateKey!,
            score: score,
            bonusXp: widget.dailyChallenge!.bonusXp,
            solutionViewed: _solutionViewed,
          );
    } else {
      await ref.read(gameProgressProvider.notifier).completeTask(
            task,
            score: score,
            solutionViewed: _solutionViewed,
          );
    }
    await ref
        .read(masteryRepositoryProvider)
        .recordAttempt(task.skillKey, score);
    final attemptMode = widget.isDaily
        ? 'daily'
        : widget.reviewMode
            ? 'review'
            : 'career';
    await ref.read(taskPerformanceRepositoryProvider).recordTask(
          task,
          score,
          mode: attemptMode,
        );
    ref.invalidate(skillProfileProvider);
    ref.invalidate(reviewQueueProvider);
    ref.invalidate(adaptiveRecommendationsProvider);
    ref.invalidate(portfolioSnapshotProvider);
    ref.invalidate(promotionReviewProvider);
    ref.invalidate(companyChapterReviewProvider);
    if (widget.isDaily) {
      ref.invalidate(dailyChallengeProvider);
    }

    if (!mounted) return;
    final progress = ref.read(gameProgressProvider);
    setState(() {
      _submitting = false;
      _solved = true;
      _feedback = widget.isDaily
          ? '${grade.feedback}\nDaily score: $score/100. Streak: ${progress.dailyStreak} day(s). Bonus XP awarded.'
          : widget.reviewMode
              ? '${grade.feedback}\nReview score: $score/100. Mastery and next review date updated.'
              : '${grade.feedback}\nScore: $score/100. XP, company metrics and ${task.skill} mastery updated.${_solutionViewed ? '\nSolution viewed: 5 XP deducted from this task reward.' : ''}';
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
                Text(title, style: Theme.of(context).textTheme.labelLarge),
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
                    DataCell(Text((row[column] ?? 'NULL').toString())),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SqlResultTable extends StatelessWidget {
  const _SqlResultTable({
    required this.columns,
    required this.rows,
  });

  final List<String> columns;
  final List<Map<String, Object?>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('Query returned 0 rows.');
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
                    DataCell(Text((row[column] ?? 'NULL').toString())),
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

class _MultiSelectAnswer extends StatelessWidget {
  const _MultiSelectAnswer({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final Set<String> selected;
  final void Function(String option, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in options)
          CheckboxListTile(
            value: selected.contains(option),
            title: Text(option),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) => onChanged(option, value ?? false),
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
            Text('Hints', style: Theme.of(context).textTheme.titleMedium),
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
