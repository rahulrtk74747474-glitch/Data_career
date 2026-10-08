import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/flagship_attempt.dart';
import '../../models/job_ready_v15.dart';
import '../../services/analyst_mistake_diagnostics.dart';
import '../../services/ecommerce_flagship_case_service.dart';
import '../../services/company_flagship_case_service.dart';
import '../../services/flagship_workday_scoring_service.dart';
import '../../services/open_ended_decision_service.dart';
import '../../services/manager_explanation_service.dart';
import '../../services/sql_result_grader.dart';
import '../campaign/career_campaign_screen.dart';
import '../game/game_providers.dart';
import 'job_ready_providers.dart';
import 'next_day_consequence_screen.dart';

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
    extends ConsumerState<FlagshipWorkdayScreen> with WidgetsBindingObserver {
  final _analysisController = TextEditingController();
  final _managerController = TextEditingController();
  final _statisticsController = TextEditingController();
  final _chartController = TextEditingController();
  final _selectedIssues = <String>{};
  String _tool = '';
  int _hintLevel = 0;
  String _statistics = '';
  String _chart = '';
  FlagshipAttempt? _attempt;
  EcommerceCaseAudit? _caseAudit;
  Map<String, List<Map<String, Object?>>>? _rawCaseTables;
  String? _caseError;
  bool _loading = true;
  bool _busy = false;
  Timer? _draftTimer;
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
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(_load);
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    // Save the latest text once more if the learner navigates back quickly.
    // Already-completed answers remain unchanged.
    if (_attempt != null && !_busy) {
      unawaited(ref.read(flagshipAttemptRepositoryProvider)
          .save(_withUnfinishedDrafts(_attempt!)));
    }
    WidgetsBinding.instance.removeObserver(this);
    _analysisController.dispose();
    _managerController.dispose();
    _statisticsController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await ref.read(learningTelemetryServiceProvider).recordEvent(
          'workday_start',
        );
    ref.invalidate(learningHealthProvider);
    EcommerceCaseAudit? audit;
    Map<String, List<Map<String, Object?>>>? tables;
    try {
      if (item.companyKey == 'ecommerce') {
        final workspace = EcommerceFlagshipCaseService(
          ref.read(appDatabaseProvider),
        );
        audit = await workspace.audit();
        tables = await workspace.exportTables();
      } else if (CompanyFlagshipCaseService.validCases.contains(item.companyKey)) {
        final workspace = CompanyFlagshipCaseService(
          ref.read(appDatabaseProvider),
        );
        tables = {
          'raw_events': await workspace.rows(item.companyKey),
          'clean_latest_events': await workspace.cleanedRows(item.companyKey),
        };
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _caseError = 'Cannot load the versioned local case data: $error';
        _loading = false;
      });
      return;
    }
    final attempt = await ref
        .read(flagshipAttemptRepositoryProvider)
        .load(item.id);
    if (!mounted) return;
    setState(() {
      _caseAudit = audit;
      _rawCaseTables = tables;
      _attempt = attempt;
      _selectedIssues
        ..clear()
        ..addAll(attempt.selectedIssues);
      _tool = attempt.tool;
      _hintLevel = attempt.hintsUsed.clamp(0, 3).toInt();
      _analysisController.text = attempt.analysisText;
      _statistics = attempt.statisticsAnswer;
      _chart = attempt.chartAnswer;
      _statisticsController.text = attempt.statisticsAnswer;
      _chartController.text = attempt.chartAnswer;
      _managerController.text = attempt.managerText;
      _loading = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _draftTimer?.cancel();
      if (_attempt != null && !_busy) {
        unawaited(_saveUnfinishedDrafts());
      }
    }
  }

  /// Every field persists without awarding any XP or completing any stage.
  FlagshipAttempt _withUnfinishedDrafts(FlagshipAttempt value) =>
      value.copyWith(
        selectedIssues: value.stageDone('quality') ? null : {..._selectedIssues},
        tool: value.stageDone('tool') ? null : _tool,
        analysisText: value.stageDone('analysis') ? null : _analysisController.text,
        statisticsAnswer: value.stageDone('statistics')
            ? null
            : item.order >= 3 ? _statisticsController.text : _statistics,
        chartAnswer: value.stageDone('chart')
            ? null
            : item.order >= 3 ? _chartController.text : _chart,
        managerText: value.stageDone('manager') ? null : _managerController.text,
      );

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 850), () {
      if (mounted && !_busy) unawaited(_saveUnfinishedDrafts());
    });
  }

  Future<void> _saveUnfinishedDrafts() async {
    final current = _attempt;
    if (current == null) return;
    try {
      await _save(_withUnfinishedDrafts(current));
    } catch (error) {
      if (mounted) {
        setState(() => _feedback = 'Draft could not be saved locally: $error');
      }
    }
  }

  bool _done(String stage) => _attempt?.stageDone(stage) ?? false;

  @override
  Widget build(BuildContext context) {
    if (_caseError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(item.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(_caseError!),
          ),
        ),
      );
    }
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
                  if (_caseAudit != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Full SQLite source: ${_caseAudit!.rawOrderEvents} order events / '
                      '${_caseAudit!.uniqueOrders} unique orders, '
                      '${_caseAudit!.rawRefundEvents} refund events / '
                      '${_caseAudit!.uniqueRefunds} unique refunds.',
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Raw duplicate events are intentional. Review all source tables; '
                      'a real SQL view deduplicates order_id and refund_id by latest ingestion.',
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showRawCaseData,
                      icon: const Icon(Icons.table_view_outlined),
                      label: const Text('Inspect all raw data and schema'),
                    ),
                  ],
                  if (_rawCaseTables != null && _caseAudit == null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'A complete source dataset is available. Event updates '
                      'and duplicates require the deduplicated latest-event view.',
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showRawCaseData,
                      icon: const Icon(Icons.table_view_outlined),
                      label: const Text('Inspect full company case dataset'),
                    ),
                  ],
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
                          : (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedIssues.add(option);
                                } else {
                                  _selectedIssues.remove(option);
                                }
                              });
                              _scheduleDraftSave();
                            },
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
              available: _done('quality'),
              title: 'Choose your tool',
              done: _done('tool'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.companyKey == 'ecommerce' ||
                            CompanyFlagshipCaseService.validCases.contains(item.companyKey)
                        ? 'Executable SQL is required for verified flagship project evidence.'
                        : 'Choose the approach you would defend in a real job.',
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
                          onSelected: _done('tool') ||
                                  (CompanyFlagshipCaseService.validCases.contains(item.companyKey) && tool != 'SQL') || (item.companyKey == 'ecommerce' && tool != 'SQL')
                              ? null
                              : (_) {
                                  setState(() => _tool = tool);
                                  _scheduleDraftSave();
                                },
                        ),
                    ],
                  ),
                  if (item.companyKey == 'ecommerce' ||
                      CompanyFlagshipCaseService.validCases.contains(item.companyKey))
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Verified flagship cases use executable SQL. '
                        'Other tools remain available in their practice labs; '
                        'the SQL path earns verified project evidence.',
                      ),
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
              available: _done('tool'),
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
                        : _tool == 'SQL' &&
                                CompanyFlagshipCaseService.validCases.contains(item.companyKey)
                            ? 'Query dq_case_latest and filter case_id = the '
                                'company key. Deduplicate events using the view; '
                                'derive ratios from total numerator / total denominator.'
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
                    onChanged: (_) {
                      setState(() {});
                      _scheduleDraftSave();
                    },
                    decoration: InputDecoration(
                      labelText: _tool.isEmpty
                          ? 'Analysis work'
                          : '$_tool workbench',
                      hintText: _toolPlaceholder(_tool),
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (item.companyKey == 'ecommerce' && !_done('analysis')) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _hintLevel >= 3 || _busy
                          ? null
                          : _showNextHint,
                      icon: const Icon(Icons.lightbulb_outline),
                      label: Text('Reveal SQL hint ($_hintLevel/3 used)'),
                    ),
                    if (_hintLevel > 0)
                      Text(
                        const [
                          'Hint 1: Raw order/refund event rows are intentionally duplicated. Use ec_case_clean_orders rather than summing ec_case_order_events.',
                          'Hint 2: Join ec_case_clean_orders to ec_case_customers using customer_id; filter only completed orders.',
                          'Hint 3: SELECT c.segment, SUM(o.net_revenue) AS revenue FROM ec_case_clean_orders o JOIN ec_case_customers c ON c.customer_id = o.customer_id WHERE o.status = completed (use quotes around completed) GROUP BY c.segment.',
                        ][_hintLevel - 1],
                      ),
                    const Text(
                      'Hint use is saved and caps independent analysis score: 95 / 85 / 75.',
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _done('analysis') ||
                            _analysisController.text.trim().isEmpty ||
                            _busy
                        ? null
                        : () => _saveDraft(analysis: true),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save analysis draft'),
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
              available: _done('analysis'),
              title: 'Challenge the interpretation',
              done: _done('statistics'),
              child: item.order >= 3
                  ? _OpenEndedDecisionStage(
                      prompt: item.statisticsPrompt,
                      controller: _statisticsController,
                      enabled: !_done('statistics'),
                      stageName: 'Statistical reasoning',
                      onChanged: () {
                        setState(() {});
                        _scheduleDraftSave();
                      },
                      onSubmit: _statisticsController.text.trim().isEmpty ||
                              _done('statistics') || _busy
                          ? null
                          : _submitStatistics,
                    )
                  : _SingleChoiceStage(
                      prompt: item.statisticsPrompt,
                      options: item.statisticsOptions,
                      value: _statistics,
                      enabled: !_done('statistics'),
                      onChanged: (value) {
                        setState(() => _statistics = value);
                        _scheduleDraftSave();
                      },
                      onSubmit: _done('statistics') || _statistics.isEmpty || _busy
                          ? null
                          : _submitStatistics,
                    ),
            ),
            _TimelineStep(
              time: _timeline['chart']!,
              available: _done('statistics'),
              title: 'Design the decision view',
              done: _done('chart'),
              child: item.order >= 3
                  ? _OpenEndedDecisionStage(
                      prompt: item.chartPrompt,
                      controller: _chartController,
                      enabled: !_done('chart'),
                      stageName: 'Dashboard/metric justification',
                      onChanged: () {
                        setState(() {});
                        _scheduleDraftSave();
                      },
                      onSubmit: _chartController.text.trim().isEmpty ||
                              _done('chart') || _busy
                          ? null
                          : _submitChart,
                    )
                  : _SingleChoiceStage(
                      prompt: item.chartPrompt,
                      options: item.chartOptions,
                      value: _chart,
                      enabled: !_done('chart'),
                      onChanged: (value) {
                        setState(() => _chart = value);
                        _scheduleDraftSave();
                      },
                      onSubmit: _done('chart') || _chart.isEmpty || _busy
                          ? null
                          : _submitChart,
                    ),
            ),
            _TimelineStep(
              time: _timeline['manager']!,
              available: _done('chart'),
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
                    onChanged: (_) {
                      setState(() {});
                      _scheduleDraftSave();
                    },
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
                  OutlinedButton.icon(
                    onPressed: _done('manager') ||
                            _managerController.text.trim().isEmpty || _busy
                        ? null
                        : () => _saveDraft(analysis: false),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save manager-update draft'),
                  ),
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('Unfinished work saves automatically on this device.'),
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
                onConsequences: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NextDayConsequenceScreen(
                      caseKey: item.companyKey,
                      companyName: item.companyName,
                    ),
                  ),
                ),
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
    final newStages = next.completedStages.difference(
      _attempt?.completedStages ?? const <String>{},
    );
    _draftTimer?.cancel();
    final stored = _withUnfinishedDrafts(next);
    await ref.read(flagshipAttemptRepositoryProvider).save(stored);
    for (final stage in newStages) {
      await ref.read(learningTelemetryServiceProvider).recordEvent(
            'stage_${stage}_complete',
          );
    }
    if (newStages.isNotEmpty) {
      ref.invalidate(learningHealthProvider);
    }
    if (!mounted) return;
    setState(() => _attempt = stored);
    ref.invalidate(flagshipAttemptsProvider);
    ref.invalidate(flagshipAttemptProvider(item.id));
  }

  Future<void> _showNextHint() async {
    if (_hintLevel >= 3 || _done('analysis')) return;
    final next = _hintLevel + 1;
    await _save(_attempt!.copyWith(hintsUsed: next));
    if (!mounted) return;
    setState(() => _hintLevel = next);
  }

  Future<void> _saveDraft({required bool analysis}) async {
    if (_busy) return;
    setState(() => _busy = true);
    await _save(_attempt!.copyWith(
      analysisText: analysis ? _analysisController.text : null,
      managerText: analysis ? null : _managerController.text,
    ));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _feedback = analysis
          ? 'Analysis draft saved locally. No assessment score awarded yet.'
          : 'Manager update saved locally as a draft.';
    });
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
      if (item.companyKey == 'ecommerce' ||
          CompanyFlagshipCaseService.validCases.contains(item.companyKey)) {
        final warning = item.companyKey == 'ecommerce'
            ? EcommerceFlagshipCaseService.queryIntegrityWarning(
                _analysisController.text,
              )
            : CompanyFlagshipCaseService.integrityWarning(
                _analysisController.text, item.companyKey,
              );
        if (warning != null) {
          setState(() {
            _busy = false;
            _feedback = warning;
          });
          return;
        }
      }
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
        truncated: run.truncated,
      );
      final changedData = !grade.isCorrect
          ? null
          : item.companyKey == 'ecommerce'
              ? await EcommerceFlagshipCaseService(
                  ref.read(appDatabaseProvider),
                ).verifyChangedData(_analysisController.text)
              : CompanyFlagshipCaseService.validCases.contains(item.companyKey)
                  ? await CompanyFlagshipCaseService(
                      ref.read(appDatabaseProvider),
                    ).verifyChangedData(
                      item.companyKey, _analysisController.text,
                    )
                  : null;
      final accepted = grade.isCorrect && (changedData?.isCorrect ?? true);
      score = accepted ? 100 : 0;
      feedback = accepted
          ? 'Correct. The query also works after case data changes.'
          : changedData != null && !changedData.isCorrect
              ? 'The example numbers match, but the SQL fails on changed data. '
                  'Compute totals from the rows instead of fixed values.'
              : AnalystMistakeDiagnostics.sql(
                  query: _analysisController.text,
                  graderFeedback: grade.feedback,
                  actualRowCount: run.rows.length,
                  expectedRowCount: item.sqlExpectedRows.length,
                );
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
    if (item.companyKey == 'ecommerce') {
      final cap = switch (_hintLevel) {
        1 => 95,
        2 => 85,
        3 => 75,
        _ => 100,
      };
      score = score.clamp(0, cap).toInt();
      if (_hintLevel > 0) {
        feedback = '$feedback\n$_hintLevel hint(s) used; independent score capped at $cap.';
      }
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
    final advanced = item.order >= 3;
    final answer = advanced ? _statisticsController.text.trim() : _statistics;
    final grade = advanced
        ? OpenEndedDecisionService.grade(
            workdayId: item.id,
            stage: 'statistics',
            answer: answer,
          )
        : null;
    if (advanced ? !grade!.passed : answer != item.statisticsExpected) {
      setState(() {
        _feedback = advanced
            ? 'Statistical review: ${grade!.score}/100. ${grade.feedback}'
            : 'Not yet. Check denominators, subgroup mix and whether the data justifies a causal claim.';
      });
      return;
    }
    await _save(_attempt!.copyWith(
      statisticsAnswer: answer,
      statisticsScore: grade?.score ?? 100,
      completedStages: {..._attempt!.completedStages, 'statistics'},
    ));
    if (!mounted) return;
    setState(() => _feedback =
        'Statistical interpretation accepted: ${grade?.score ?? 100}/100.');
  }

  Future<void> _submitChart() async {
    final advanced = item.order >= 3;
    final answer = advanced ? _chartController.text.trim() : _chart;
    final grade = advanced
        ? OpenEndedDecisionService.grade(
            workdayId: item.id,
            stage: 'chart',
            answer: answer,
          )
        : null;
    if (advanced ? !grade!.passed : answer != item.chartExpected) {
      setState(() {
        _feedback = advanced
            ? 'Dashboard review: ${grade!.score}/100. ${grade.feedback}'
            : 'Match the visual to the comparison, time grain, metric definition and business decision.';
      });
      return;
    }
    await _save(_attempt!.copyWith(
      chartAnswer: answer,
      chartScore: grade?.score ?? 100,
      completedStages: {..._attempt!.completedStages, 'chart'},
    ));
    if (!mounted) return;
    setState(() => _feedback =
        'Dashboard decision accepted: ${grade?.score ?? 100}/100.');
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
    final overclaim = AnalystMistakeDiagnostics.managerOverclaim(
      _managerController.text,
    );
    if (overclaim != null) {
      setState(() => _feedback = overclaim);
      return;
    }
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
    setState(() => _busy = true);
    try {
      final result = await ref.read(flagshipProjectExportServiceProvider)
          .export(workday: item, attempt: _attempt!);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('GitHub-ready project created'),
          content: SelectableText(
            '${result.fileCount} project files packaged into a shareable ZIP:\n\n'
            '${result.archivePath}\n\n'
            'Includes your analysis, datasets, review, verification '
            'and reproduction instructions.',
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ref.read(portfolioDeliveryServiceProvider).share(
                    result.archivePath,
                    title: 'DataQuest Synthetic Analyst Project',
                    text: 'Reproducible synthetic analytics project '
                        'with source data, SQL and a verification report.',
                  );
                } catch (error) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not share ZIP: $error')),
                  );
                }
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share ZIP'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export project: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showRawCaseData() async {
    final tables = _rawCaseTables;
    if (tables == null || !mounted) return;
    final ecommerce = item.companyKey == 'ecommerce';
    final displayKeys = ecommerce
        ? const ['customers', 'order_events', 'refund_events', 'clean_orders']
        : const ['raw_events', 'clean_latest_events'];
    final schema = ecommerce
        ? {
            'source_tables': [
              'ec_case_customers', 'ec_case_order_events',
              'ec_case_refund_events',
            ],
            'clean_view': 'ec_case_clean_orders',
          }
        : {
            'source_tables': ['dq_case_events'],
            'clean_view': 'dq_case_latest',
            'required_case_id': item.companyKey,
          };
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Full ${item.companyName} source data'),
        content: SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ecommerce
                    ? 'These are all the synthetic e-commerce source records. '
                        'Order and refund events include duplicate and late updates.'
                    : 'These are all synthetic ${item.companyKey} event records. '
                        'The latest-event view deduplicates business records '
                        'by company case and event ingestion time.'),
                const SizedBox(height: 10),
                for (final key in displayKeys) ...[
                  Text(
                    key,
                    style: Theme.of(dialogContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  _PreviewTable(
                    rows: [
                      for (final row in tables[key] ?? const <Map<String, Object?>>[])
                        Map<String, dynamic>.from(row),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                Text(ecommerce
                    ? 'Revenue definition: completed orders minus distinct '
                        'partial refunds; a snapshot does not establish growth.'
                    : 'Use dq_case_latest filtered to case_id = '
                        '${item.companyKey}. Aggregate only eligible status '
                        'records. Single-period metrics do not establish causality.'),
                const SizedBox(height: 8),
                SelectableText(
                  const JsonEncoder.withIndent('  ').convert(schema),
                ),
              ],
            ),
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
        return 'Write a complete read-only SQL query. It runs against real local SQLite tables. '
            'For the e-commerce flagship join ec_case_clean_orders to ec_case_customers '
            'and aggregate net_revenue by segment.';
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
    this.available = true,
    required this.child,
  });

  final String time;
  final String title;
  final bool done;
  final bool available;
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
            if (available || done)
              child
            else
              const Text(
                'This stage is locked. Complete the previous work stage first so your decision uses the evidence already produced.',
              ),
          ],
        ),
      ),
    );
  }
}

class _OpenEndedDecisionStage extends StatelessWidget {
  const _OpenEndedDecisionStage({
    required this.prompt,
    required this.controller,
    required this.enabled,
    required this.stageName,
    required this.onChanged,
    required this.onSubmit,
  });

  final String prompt;
  final TextEditingController controller;
  final bool enabled;
  final String stageName;
  final VoidCallback onChanged;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt),
          const SizedBox(height: 8),
          const Text(
            'Independent assessment: explain your decision instead of guessing from options. The offline rubric checks essential concepts, but you must still defend your reasoning.',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled,
            minLines: 4,
            maxLines: 8,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              labelText: stageName,
              hintText: 'State the metric or comparison, your reasoning and any limitation.',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onSubmit,
            child: const Text('Submit independent decision'),
          ),
        ],
      );
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
    required this.onConsequences,
  });

  final FlagshipWorkday workday;
  final FlagshipAttempt attempt;
  final VoidCallback onExport;
  final VoidCallback onConsequences;

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
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onConsequences,
              icon: const Icon(Icons.trending_up_outlined),
              label: const Text('Next morning: see your decision consequences'),
            ),
          ],
        ),
      ),
    );
  }
}
