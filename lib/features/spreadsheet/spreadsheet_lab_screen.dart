import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/spreadsheet_challenge.dart';
import '../../services/spreadsheet_simulator.dart';
import '../../widgets/solution_reveal_card.dart';
import '../game/game_providers.dart';

class SpreadsheetLabScreen extends ConsumerStatefulWidget {
  const SpreadsheetLabScreen({super.key});

  @override
  ConsumerState<SpreadsheetLabScreen> createState() =>
      _SpreadsheetLabScreenState();
}

class _SpreadsheetLabScreenState extends ConsumerState<SpreadsheetLabScreen> {
  String _skillFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final challenges = ref.watch(spreadsheetChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Spreadsheet & Cleaning Lab')),
      body: SafeArea(
        child: challenges.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load spreadsheet lab.\n$error'),
          ),
          data: (items) {
            final filtered = _skillFilter == 'all'
                ? items
                : items
                    .where((item) => item.skillKey == _skillFilter)
                    .toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Touch-first workbook simulator',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Use shortcut chips to build safe workbook commands for formulas, lookups, sorting, filtering, pivots and data cleaning. The table is swipeable and all grading runs offline.',
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All')),
                    ButtonSegment(
                      value: 'spreadsheets',
                      label: Text('Spreadsheet'),
                    ),
                    ButtonSegment(
                      value: 'cleaning',
                      label: Text('Cleaning'),
                    ),
                  ],
                  selected: {_skillFilter},
                  onSelectionChanged: (value) {
                    setState(() => _skillFilter = value.first);
                  },
                ),
                const SizedBox(height: 16),
                for (final item in filtered)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        item.skillKey == 'cleaning'
                            ? Icons.cleaning_services_outlined
                            : Icons.table_chart_outlined,
                      ),
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.skillKey == 'cleaning' ? 'Data Cleaning' : 'Spreadsheets'} • ${item.difficulty} • ${item.companyKey}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              _SpreadsheetChallengeScreen(challenge: item),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SpreadsheetChallengeScreen extends ConsumerStatefulWidget {
  const _SpreadsheetChallengeScreen({required this.challenge});

  final SpreadsheetChallenge challenge;

  @override
  ConsumerState<_SpreadsheetChallengeScreen> createState() =>
      _SpreadsheetChallengeScreenState();
}

class _SpreadsheetChallengeScreenState
    extends ConsumerState<_SpreadsheetChallengeScreen> {
  final _commandController = TextEditingController();
  SpreadsheetRunResult? _result;
  int _revealedHints = 0;
  int _failedAttempts = 0;
  bool _solved = false;
  bool _solutionViewed = false;
  int _earnedXp = 0;

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.challenge;

    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${item.skillKey == 'cleaning' ? 'Data Cleaning' : 'Spreadsheets'} • ${item.difficulty}',
            ),
            const SizedBox(height: 10),
            Text(item.context),
            const SizedBox(height: 14),
            Text(
              item.prompt,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _SwipeTable(rows: item.rows),
            const SizedBox(height: 14),
            Text(
              'Workbook shortcut bar',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final shortcut in SpreadsheetSimulator.shortcuts)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(shortcut.trim()),
                        onPressed: _solved
                            ? null
                            : () {
                                final current =
                                    _commandController.text.trimRight();
                                _commandController.text =
                                    current.isEmpty
                                        ? shortcut
                                        : '$current $shortcut';
                                _commandController.selection =
                                    TextSelection.collapsed(
                                  offset: _commandController.text.length,
                                );
                              },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Workbook action syntax'),
              subtitle: const Text(
                'Formula, lookup, sort, filter, pivot and cleaning commands',
              ),
              children: [
                for (final entry in SpreadsheetSimulator.commandHelp.entries)
                  ListTile(
                    dense: true,
                    title: Text(entry.key),
                    subtitle: Text(entry.value),
                    onTap: _solved
                        ? null
                        : () {
                            _commandController.text = entry.value;
                            _commandController.selection =
                                TextSelection.collapsed(
                              offset: _commandController.text.length,
                            );
                          },
                  ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _commandController,
              enabled: !_solved,
              minLines: 2,
              maxLines: 4,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Workbook command',
                hintText:
                    'Example: PIVOT region SUM revenue',
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _solved ? null : _run,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run workbook action'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(_result!.feedback),
                ),
              ),
              if (_result!.rows.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Workbook result',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                _SwipeTable(rows: _result!.rows),
              ],
            ],
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hints',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    for (var i = 0; i < _revealedHints; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('${i + 1}. ${item.hints[i]}'),
                      ),
                    OutlinedButton.icon(
                      onPressed: _solved ||
                              _revealedHints >= item.hints.length
                          ? null
                          : () {
                              setState(() => _revealedHints++);
                            },
                      icon: const Icon(Icons.lightbulb_outline),
                      label: Text(
                        _revealedHints >= item.hints.length
                            ? 'All hints revealed'
                            : 'Reveal hint ${_revealedHints + 1}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SolutionRevealCard(
              solution: item.solutionText,
              revealed: _solutionViewed,
              penaltyApplies: !_solved,
              onReveal: _solutionViewed
                  ? null
                  : () => setState(() => _solutionViewed = true),
            ),
            if (_earnedXp > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('XP earned: $_earnedXp'),
              ),
            if (_solved) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why this works',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(item.explanation),
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

  Future<void> _run() async {
    final result = SpreadsheetSimulator.run(
      widget.challenge,
      _commandController.text,
    );
    if (!result.isCorrect) {
      setState(() {
        _result = result;
        _failedAttempts++;
      });
      return;
    }

    final score = (100 - _revealedHints * 15 - _failedAttempts * 10)
        .clamp(40, 100)
        .toInt();

    final earnedXp =
        await ref.read(gameProgressProvider.notifier).awardLearningXp(
              rewardId: 'spreadsheet:${widget.challenge.id}',
              baseXp: widget.challenge.xp,
              score: score,
              solutionViewed: _solutionViewed,
            );
    await ref.read(masteryRepositoryProvider).recordAttempt(
          widget.challenge.skillKey,
          score,
        );
    await ref.read(taskPerformanceRepositoryProvider).record(
          id: widget.challenge.id,
          title: widget.challenge.title,
          skillKey: widget.challenge.skillKey,
          difficulty: widget.challenge.difficulty,
          score: score,
          mode: 'spreadsheet_lab',
          companyKey: widget.challenge.companyKey,
        );

    ref.invalidate(skillProfileProvider);
    ref.invalidate(reviewQueueProvider);
    ref.invalidate(portfolioSnapshotProvider);
    ref.invalidate(jobReadinessProvider);

    if (!mounted) return;
    setState(() {
      _result = result;
      _solved = true;
      _earnedXp = earnedXp;
    });
  }
}

class _SwipeTable extends StatelessWidget {
  const _SwipeTable({required this.rows});

  final List<Map<String, Object?>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('No rows');

    final columns = <String>[];
    for (final row in rows) {
      for (final key in row.keys) {
        if (!columns.contains(key)) columns.add(key);
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: DataTable(
          columns: [
            for (final column in columns)
              DataColumn(label: Text(column)),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  for (final column in columns)
                    DataCell(Text(row[column]?.toString() ?? '')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
