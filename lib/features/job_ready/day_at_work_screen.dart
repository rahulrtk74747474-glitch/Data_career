import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/flagship_attempt.dart';
import '../../models/job_ready_v15.dart';
import '../../services/flagship_workday_scoring_service.dart';
import '../../services/manager_explanation_service.dart';
import '../../services/sql_result_grader.dart';
import '../campaign/career_campaign_screen.dart';
import '../game/game_providers.dart';
import 'job_ready_providers.dart';

class DayAtWorkHubScreen extends ConsumerWidget {
  const DayAtWorkHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workdays = ref.watch(flagshipWorkdaysProvider);
    final attempts = ref.watch(flagshipAttemptsProvider);
    final progress = ref.watch(gameProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Day at Work')),
      body: SafeArea(
        child: workdays.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (items) => attempts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('$error')),
            data: (saved) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  'Report to work. Solve the whole business problem.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Each flagship day runs from morning briefing to end-of-day manager review: dirty data → tool choice → analysis → statistics → dashboard → executive explanation.',
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.work_history_outlined),
                    ),
                    title: const Text(
                      'Career Campaign',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Continue the 12 connected company projects and promotion journey.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CareerCampaignScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Flagship portfolio workdays',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                for (final item in items) ...[
                  _WorkdayTile(
                    item: item,
                    attempt: saved[item.id],
                    unlocked:
                        progress.resolvedCompanyChapter >= item.order - 1,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkdayTile extends StatelessWidget {
  const _WorkdayTile({
    required this.item,
    required this.attempt,
    required this.unlocked,
  });

  final FlagshipWorkday item;
  final FlagshipAttempt? attempt;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final completed = attempt?.isComplete ?? false;
    final completedStages = attempt?.completedStages.length ?? 0;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          child: completed
              ? const Icon(Icons.workspace_premium_outlined)
              : unlocked
                  ? Text(item.order.toString())
                  : const Icon(Icons.lock_outline),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          completed
              ? '${item.companyName} • Portfolio project • ${attempt!.totalScore}/100'
              : unlocked
                  ? '${item.companyName} • ${item.startTime}–${item.endTime} • $completedStages/6 stages saved'
                  : '${item.companyName} • Unlock this company chapter first',
        ),
        trailing: Icon(
          completed
              ? Icons.verified_outlined
              : unlocked
                  ? Icons.chevron_right
                  : Icons.lock,
        ),
        onTap: !unlocked
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FlagshipWorkdayScreen(workday: item),
                  ),
                ),
      ),
    );
  }
}

class FlagshipWorkdayScreen extends ConsumerStatefulWidget {
  const FlagshipWorkdayScreen({
    super.key,
    required this.workday,
  });

  final FlagshipWorkday workday;

  @override
  ConsumerState<FlagshipWorkdayScreen> createState() =>
      _FlagshipWorkdayScreenState();
}

class _FlagshipWorkdayScreenState
    extends ConsumerState<FlagshipWorkdayScreen> {
  final _analysisController = TextEditingController();
  final _managerController = TextEditingController();
  final _selectedIssues = <String>{};
  String _tool = '';
  String _statistics = '';
  String _chart = '';
  FlagshipAttempt? _attempt;
  bool _loading = true;
  bool _busy = false;
  String? _feedback;
  ManagerExplanationScore? _managerRubric;

  FlagshipWorkday get item => widget.workday;

  static const _timeline = <String, String>{
    'quality': '09:40',
    'tool': '10:20',
    'analysis': '11:00',
    'statistics': '13:20',
    'chart': '14:20',
    'manager': '15:30',
  };

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
  }

  @override
  void dispose() {
    _analysisController.dispose();
    _managerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await ref.read(learningTelemetryServiceProvider).recordEvent(
          'workday_start',
        );
    ref.invalidate(learningHealthProvider);
    final attempt = await ref
        .read(flagshipAttemptRepositoryProvider)
        .load(item.id);
    if (!mounted) return;
    setState(() {
      _attempt = attempt;
      _selectedIssues
        ..clear()
        ..addAll(attempt.selectedIssues);
      _tool = attempt.tool;
      _analysisController.text = attempt.analysisText;
      _statistics = attempt.statisticsAnswer;
      _chart = attempt.chartAnswer;
      _managerController.text = attempt.managerText;
      _loading = false;
    });
  }

  bool _done(String stage) => _attempt?.stageDone(stage) ?? false;

  @override
  Widget build(BuildContext context) {
    if (_loading || _attempt == null) {
      return Scaffold(
        appBar: AppBar(title: Text(item.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _Header(item: item, attempt: _attempt!),
            const SizedBox(height: 12),
            _TimelineStep(
              time: item.startTime,
              title: 'Manager briefing',
              done: true,
              child: Text(item.briefing),
            ),
            _TimelineStep(
              time: _timeline['quality']!,
              title: 'Inspect the raw data',
              done: _done('quality'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.datasetName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _PreviewTable(rows: item.previewRows),
                  const SizedBox(height: 10),
                  const Text(
                    'Select every issue/control that matters before analysis.',
                  ),
                  for (final option in item.issueOptions)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _selectedIssues.contains(option),
                      title: Text(option),
                      onChanged: _done('quality')
                          ? null
                          : (value) => setState(() {
                                if (value == true) {
                                  _selectedIssues.add(option);
                                } else {
                                  _selectedIssues.remove(option);
                                }
                              }),
                    ),
                  FilledButton(
                    onPressed: _done('quality') || _busy
                        ? null
                        : _submitQuality,
                    child: const Text('Validate data-quality review'),
                  ),
                ],
              ),
            ),
            _TimelineStep(
              time: _timeline['tool']!,
              title: 'Choose your tool',
              done: _done('tool'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No tool is prescribed. Choose the approach you would defend in a real job.',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tool in item.toolScores.keys)
                        ChoiceChip(
                          label: Text(tool),
                          selected: _tool == tool,
                          onSelected: _done('tool')
                              ? null
                              : (_) => setState(() => _tool = tool),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed:
                        _done('tool') || _tool.isEmpty || _busy
                            ? null
                            : _submitTool,
                    child: const Text('Commit to approach'),
                  ),
                ],
              ),
            ),
            _TimelineStep(
              time: _timeline['analysis']!,
              title: 'Do the analysis',
              done: _done('analysis'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.analysisPrompt),
                  const SizedBox(height: 8),
                  Text(
                    _tool.isEmpty
                        ? 'Choose your tool first.'
                        : _toolHint(_tool),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _analysisController,
                    enabled: !_done('analysis') && _tool.isNotEmpty,
                    minLines: 7,
                    maxLines: 14,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: _tool.isEmpty
                          ? 'Analysis work'
                          : '$_tool workbench',
                      hintText: _toolPlaceholder(_tool),
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _done('analysis') ||
                            _tool.isEmpty ||
                            _analysisController.text.trim().isEmpty ||
                            _busy
                        ? null
                        : _runAnalysis,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      _tool == 'SQL'
                          ? 'Run SQL against local database'
                          : 'Validate $_tool work',
                    ),
                  ),
                ],
              ),
            ),
            _TimelineStep(
              time: _timeline['statistics']!,
              title: 'Challenge the interpretation',
              done: _done('statistics'),
              child: _SingleChoiceStage(
                prompt: item.statisticsPrompt,
                options: item.statisticsOptions,
                value: _statistics,
                enabled: !_done('statistics'),
                onChanged: (value) => setState(() => _statistics = value),
                onSubmit: _done('statistics') || _statistics.isEmpty
                    ? null
                    : _submitStatistics,
              ),
            ),
            _TimelineStep(
              time: _timeline['chart']!,
              title: 'Design the decision view',
              done: _done('chart'),
              child: _SingleChoiceStage(
                prompt: item.chartPrompt,
                options: item.chartOptions,
                value: _chart,
                enabled: !_done('chart'),
                onChanged: (value) => setState(() => _chart = value),
                onSubmit:
                    _done('chart') || _chart.isEmpty ? null : _submitChart,
              ),
            ),
            _TimelineStep(
              time: _timeline['manager']!,
              title: 'Explain it to the manager',
              done: _done('manager'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.managerPrompt),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _managerController,
                    enabled: !_done('manager'),
                    minLines: 5,
                    maxLines: 9,
                    decoration: const InputDecoration(
                      labelText: 'Your 2–4 sentence manager update',
                      hintText:
                          'Finding → evidence → limitation → recommendation',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_managerRubric != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Manager rubric: ${_managerRubric!.total}/100',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    for (final line in _managerRubric!.feedback)
                      Text('• $line'),
                  ],
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _done('manager') ||
                            _managerController.text.trim().isEmpty ||
                            _busy
                        ? null
                        : _submitManager,
                    child: const Text('Send manager update'),
                  ),
                ],
              ),
            ),
            if (_feedback != null) ...[
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(_feedback!),
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (_allStagesDone && !_attempt!.isComplete)
              FilledButton.icon(
                onPressed: _busy ? null : _completeWorkday,
                icon: const Icon(Icons.flag_outlined),
                label: Text('Submit end-of-day review (+${item.bonusXp} XP)'),
              ),
            if (_attempt!.isComplete)
              _CompletedProject(
                workday: item,
                attempt: _attempt!,
                onExport: _exportProject,
              ),
          ],
        ),
      ),
    );
  }

  bool get _allStagesDone => const [
        'quality',
        'tool',
        'analysis',
        'statistics',
        'chart',
        'manager',
      ].every(_done);

  Future<void> _save(FlagshipAttempt next) async {
    await ref.read(flagshipAttemptRepositoryProvider).save(next);
    if (!mounted) return;
    setState(() => _attempt = next);
    ref.invalidate(flagshipAttemptsProvider);
    ref.invalidate(flagshipAttemptProvider(item.id));
  }

  Future<void> _submitQuality() async {
    final score =
        FlagshipWorkdayScoringService.issueScore(item, _selectedIssues);
    if (score < 70) {
      setState(() {
        _feedback =
            'Data-quality score: $score/100. You missed an important control or selected an unsafe rule. Re-check grain, definitions, bias and comparability.';
      });
      return;
    }
    await _save(
      _attempt!.copyWith(
        selectedIssues: {..._selectedIssues},
        issueScore: score,
        completedStages: {..._attempt!.completedStages, 'quality'},
      ),
    );
    setState(() => _feedback = '09:40 review passed: $score/100.');
  }

  Future<void> _submitTool() async {
    final score = FlagshipWorkdayScoringService.toolScore(item, _tool);
    await _save(
      _attempt!.copyWith(
        tool: _tool,
        toolScore: score,
        completedStages: {..._attempt!.completedStages, 'tool'},
      ),
    );
    setState(() {
      _feedback = score >= 90
          ? 'Tool choice: $score/100. Strong fit for this data and decision.'
          : 'Tool choice: $score/100. Defensible, but be ready to explain trade-offs.';
    });
  }

  Future<void> _runAnalysis() async {
    setState(() => _busy = true);
    int score;
    String feedback;
    if (_tool == 'SQL') {
      final run =
          await ref.read(sqlRunnerProvider).runReadOnly(_analysisController.text);
      if (!run.isSuccess) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _feedback = run.error;
        });
        return;
      }
      final grade = SqlResultGrader.grade(
        actualRows: run.rows,
        expectedRows: item.sqlExpectedRows,
      );
      score = grade.isCorrect ? 100 : 0;
      feedback = grade.feedback;
    } else {
      score = FlagshipWorkdayScoringService.tokenAnalysisScore(
        item,
        _tool,
        _analysisController.text,
      );
      final missing = (item.tokenRules[_tool] ?? const <String>[])
          .where(
            (token) => !_analysisController.text
                .toLowerCase()
                .contains(token.toLowerCase()),
          )
          .toList();
      feedback = score >= 70
          ? 'Workbench structure is credible for the chosen tool.'
          : 'Your $_tool work is missing key elements: ${missing.join(', ')}.';
    }

    if (score < 70) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _feedback = '$feedback\nAnalysis score: $score/100.';
      });
      return;
    }

    await _save(
      _attempt!.copyWith(
        analysisText: _analysisController.text.trim(),
        analysisScore: score,
        completedStages: {..._attempt!.completedStages, 'analysis'},
      ),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _feedback = '$feedback\nAnalysis score: $score/100.';
    });
  }

  Future<void> _submitStatistics() async {
    if (_statistics != item.statisticsExpected) {
      setState(() {
        _feedback =
            'Not yet. Separate association from causation, check denominators/mix, and ask what the aggregate may be hiding.';
      });
      return;
    }
    await _save(
      _attempt!.copyWith(
        statisticsAnswer: _statistics,
        statisticsScore: 100,
        completedStages: {..._attempt!.completedStages, 'statistics'},
      ),
    );
    setState(() => _feedback = 'Statistical interpretation: 100/100.');
  }

  Future<void> _submitChart() async {
    if (_chart != item.chartExpected) {
      setState(() {
        _feedback =
            'That visual does not support the decision strongly enough. Match chart type to the comparison, time structure and diagnostic question.';
      });
      return;
    }
    await _save(
      _attempt!.copyWith(
        chartAnswer: _chart,
        chartScore: 100,
        completedStages: {..._attempt!.completedStages, 'chart'},
      ),
    );
    setState(() => _feedback = 'Dashboard decision: 100/100.');
  }

  Future<void> _submitManager() async {
    final score = ManagerExplanationService.score(
      text: _managerController.text,
      evidenceTerms: item.evidenceTerms,
      impactTerms: item.impactTerms,
      uncertaintyTerms: item.uncertaintyTerms,
      recommendationTerms: item.recommendationTerms,
    );
    setState(() => _managerRubric = score);
    if (score.total < 60) {
      setState(() {
        _feedback =
            'Manager update is ${score.total}/100. Strengthen the missing rubric areas before sending.';
      });
      return;
    }
    await _save(
      _attempt!.copyWith(
        managerText: _managerController.text.trim(),
        managerScore: score.total,
        completedStages: {..._attempt!.completedStages, 'manager'},
      ),
    );
    setState(() {
      _feedback =
          'Manager accepted the update: ${score.total}/100. You can now submit the end-of-day review.';
    });
  }

  Future<void> _completeWorkday() async {
    setState(() => _busy = true);
    final current = _attempt!;
    final total = FlagshipWorkdayScoringService.total(
      issue: current.issueScore,
      tool: current.toolScore,
      analysis: current.analysisScore,
      statistics: current.statisticsScore,
      chart: current.chartScore,
      manager: current.managerScore,
    );
    final completed = current.copyWith(
      totalScore: total,
      completedAt: DateTime.now().toUtc(),
    );
    await ref.read(flagshipAttemptRepositoryProvider).save(completed);
    await ref.read(learningTelemetryServiceProvider).recordEvent(
          'workday_complete',
        );
    ref.invalidate(learningHealthProvider);

    final earned =
        await ref.read(gameProgressProvider.notifier).awardLearningXp(
              rewardId: item.rewardId,
              baseXp: item.bonusXp,
              score: total,
            );
    await ref.read(gameProgressProvider.notifier).applyWorkDecision(
          decisionId: 'flagship-impact:${item.id}',
          baseXp: 0,
          score: total,
          trustDelta: total >= 85 ? 4 : total >= 70 ? 2 : 0,
          dataQualityDelta: total >= 85 ? 3 : 1,
          riskDelta: total >= 85 ? -3 : total >= 70 ? -1 : 0,
        );

    final mastery = ref.read(masteryRepositoryProvider);
    await mastery.recordAttempt('cleaning', current.issueScore);
    await mastery.recordAttempt(_skillForTool(current.tool), current.analysisScore);
    await mastery.recordAttempt('statistics', current.statisticsScore);
    await mastery.recordAttempt('business', current.managerScore);

    await ref.read(taskPerformanceRepositoryProvider).record(
          id: item.id,
          title: 'Flagship Project: ${item.title}',
          skillKey: 'business',
          difficulty: 'Open-ended Project',
          score: total,
          mode: 'flagship_capstone',
          companyKey: item.companyKey,
        );

    ref.invalidate(flagshipAttemptsProvider);
    ref.invalidate(flagshipAttemptProvider(item.id));
    ref.invalidate(portfolioSnapshotProvider);
    ref.invalidate(skillProfileProvider);
    ref.invalidate(jobReadinessProvider);
    ref.invalidate(achievementsProvider);

    if (!mounted) return;
    setState(() {
      _attempt = completed;
      _busy = false;
      _feedback =
          '${item.reviewFeedback}\n\nEnd-of-day score: $total/100 • XP earned: $earned.';
    });
  }

  Future<void> _exportProject() async {
    final result =
        await ref.read(flagshipProjectExportServiceProvider).export(
              workday: item,
              attempt: _attempt!,
            );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('GitHub-ready project created'),
        content: SelectableText(
          '${result.fileCount} files created:\n\n${result.directoryPath}\n\n'
          'README.md, analysis file, data_quality.md, executive_summary.md and sample_data.csv.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  static String _skillForTool(String tool) {
    switch (tool) {
      case 'SQL':
        return 'sql';
      case 'Pandas':
        return 'python';
      case 'Power BI':
        return 'powerbi';
      case 'Excel':
        return 'spreadsheets';
      default:
        return 'business';
    }
  }

  static String _toolHint(String tool) {
    switch (tool) {
      case 'SQL':
        return 'Write a complete read-only SQL query. It will run against the local SQLite company database.';
      case 'Pandas':
        return 'Write a realistic Pandas expression/pipeline using dataframe operations.';
      case 'Power BI':
        return 'Write a realistic DAX measure or model expression appropriate to the request.';
      case 'Excel':
        return 'Write a realistic Excel formula or pivot-oriented command using explicit criteria.';
      default:
        return 'Choose a tool first.';
    }
  }

  static String _toolPlaceholder(String tool) {
    switch (tool) {
      case 'SQL':
        return 'SELECT ...';
      case 'Pandas':
        return "df[...] / df.groupby(...)";
      case 'Power BI':
        return 'Measure = CALCULATE(...)';
      case 'Excel':
        return '=SUMIFS(...)';
      default:
        return '';
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.item,
    required this.attempt,
  });

  final FlagshipWorkday item;
  final FlagshipAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final progress = attempt.completedStages.length / 6;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.companyName),
            const SizedBox(height: 3),
            Text(
              item.role,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress.clamp(0, 1)),
            const SizedBox(height: 6),
            Text(
              attempt.isComplete
                  ? 'Workday complete • ${attempt.totalScore}/100'
                  : '${attempt.completedStages.length}/6 work stages complete • ${item.startTime}–${item.endTime}',
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.time,
    required this.title,
    required this.done,
    required this.child,
  });

  final String time;
  final String title;
  final bool done;
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
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  child: done
                      ? const Icon(Icons.check, size: 18)
                      : const Icon(Icons.schedule, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$time • $title',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SingleChoiceStage extends StatelessWidget {
  const _SingleChoiceStage({
    required this.prompt,
    required this.options,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onSubmit,
  });

  final String prompt;
  final List<String> options;
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt),
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        FilledButton(
          onPressed: onSubmit,
          child: const Text('Submit decision'),
        ),
      ],
    );
  }
}

class _PreviewTable extends StatelessWidget {
  const _PreviewTable({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final columns = rows.first.keys.toList();
    return SingleChildScrollView(
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
    );
  }
}

class _CompletedProject extends StatelessWidget {
  const _CompletedProject({
    required this.workday,
    required this.attempt,
    required this.onExport,
  });

  final FlagshipWorkday workday;
  final FlagshipAttempt attempt;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'End-of-day review: ${attempt.totalScore}/100',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(workday.reviewFeedback),
            const SizedBox(height: 10),
            Text(
              'Portfolio evidence',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            SelectableText(workday.resumeBullet),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.folder_zip_outlined),
              label: const Text('Create GitHub-ready project folder'),
            ),
          ],
        ),
      ),
    );
  }
}
