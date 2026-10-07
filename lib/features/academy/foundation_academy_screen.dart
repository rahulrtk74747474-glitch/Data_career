import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/foundation_lesson.dart';
import '../../widgets/solution_reveal_card.dart';
import '../game/game_providers.dart';

class FoundationAcademyScreen extends ConsumerStatefulWidget {
  const FoundationAcademyScreen({super.key});

  @override
  ConsumerState<FoundationAcademyScreen> createState() =>
      _FoundationAcademyScreenState();
}

class _FoundationAcademyScreenState
    extends ConsumerState<FoundationAcademyScreen> {
  String _track = 'all';

  @override
  Widget build(BuildContext context) {
    final lessons = ref.watch(foundationLessonsProvider);
    final progress = ref.watch(gameProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Zero-to-Analyst Academy')),
      body: SafeArea(
        child: lessons.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load beginner lessons.\n$error'),
            ),
          ),
          data: (items) {
            final grouped = <String, List<FoundationLesson>>{};
            for (final lesson in items) {
              grouped.putIfAbsent(lesson.trackKey, () => []).add(lesson);
            }
            for (final track in grouped.values) {
              track.sort((a, b) => a.order.compareTo(b.order));
            }

            if (_track == 'all') {
              return _TrackOverview(
                grouped: grouped,
                rewardedIds: progress.rewardedLearningIds,
                onOpenTrack: (track) => setState(() => _track = track),
              );
            }

            final selected = grouped[_track] ?? const <FoundationLesson>[];
            if (selected.isEmpty) {
              return Center(
                child: FilledButton(
                  onPressed: () => setState(() => _track = 'all'),
                  child: const Text('Back to learning paths'),
                ),
              );
            }

            return _TrackLessonList(
              lessons: selected,
              rewardedIds: progress.rewardedLearningIds,
              onBack: () => setState(() => _track = 'all'),
            );
          },
        ),
      ),
    );
  }
}

class _TrackOverview extends StatelessWidget {
  const _TrackOverview({
    required this.grouped,
    required this.rewardedIds,
    required this.onOpenTrack,
  });

  final Map<String, List<FoundationLesson>> grouped;
  final Set<String> rewardedIds;
  final ValueChanged<String> onOpenTrack;

  @override
  Widget build(BuildContext context) {
    final totalLessons =
        grouped.values.fold<int>(0, (sum, lessons) => sum + lessons.length);
    final completedLessons = grouped.values
        .expand((lessons) => lessons)
        .where((lesson) => rewardedIds.contains('academy:${lesson.id}'))
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          'Your job-ready learning map',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Start at zero, build confidence with guided work, then lose the training wheels. Each path ends with independent practice before the career missions.',
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completedLessons / $totalLessons foundation lessons complete',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: totalLessons == 0
                      ? 0
                      : completedLessons / totalLessons,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Guided → Assisted → Independent → Career Mission',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final entry in grouped.entries) ...[
          _TrackCard(
            trackKey: entry.key,
            lessons: entry.value,
            rewardedIds: rewardedIds,
            onTap: () => onOpenTrack(entry.key),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.trackKey,
    required this.lessons,
    required this.rewardedIds,
    required this.onTap,
  });

  final String trackKey;
  final List<FoundationLesson> lessons;
  final Set<String> rewardedIds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = lessons
        .where((lesson) => rewardedIds.contains('academy:${lesson.id}'))
        .length;
    FoundationLesson? next;
    for (final lesson in lessons) {
      if (!rewardedIds.contains('academy:${lesson.id}')) {
        next = lesson;
        break;
      }
    }
    final fraction = lessons.isEmpty ? 0.0 : completed / lessons.length;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                child: Icon(_iconForTrack(trackKey)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lessons.first.trackTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      next == null
                          ? 'Path complete • ready for projects'
                          : 'Next: ${next.title}',
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: fraction),
                    const SizedBox(height: 6),
                    Text('$completed / ${lessons.length} lessons'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                next == null ? Icons.verified_outlined : Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForTrack(String key) {
    switch (key) {
      case 'sql':
        return Icons.storage_outlined;
      case 'spreadsheets':
        return Icons.table_chart_outlined;
      case 'cleaning':
        return Icons.cleaning_services_outlined;
      case 'statistics':
        return Icons.query_stats_outlined;
      case 'python':
        return Icons.code;
      case 'dashboards':
        return Icons.dashboard_outlined;
      case 'powerbi':
        return Icons.model_training_outlined;
      default:
        return Icons.insights_outlined;
    }
  }
}

class _TrackLessonList extends StatelessWidget {
  const _TrackLessonList({
    required this.lessons,
    required this.rewardedIds,
    required this.onBack,
  });

  final List<FoundationLesson> lessons;
  final Set<String> rewardedIds;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final completed = lessons
        .where((lesson) => rewardedIds.contains('academy:${lesson.id}'))
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('All learning paths'),
          ),
        ),
        Text(
          lessons.first.trackTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          '$completed / ${lessons.length} complete • unlock one lesson at a time',
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: lessons.isEmpty ? 0 : completed / lessons.length,
        ),
        const SizedBox(height: 14),
        const _IndependenceLegend(),
        const SizedBox(height: 14),
        for (var index = 0; index < lessons.length; index++) ...[
          Builder(
            builder: (context) {
              final lesson = lessons[index];
              final completed =
                  rewardedIds.contains('academy:${lesson.id}');
              final previousComplete = index == 0 ||
                  rewardedIds.contains('academy:${lessons[index - 1].id}');
              final unlocked = completed || previousComplete;
              final stage = _stageFor(index, lessons.length);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: completed
                        ? const Icon(Icons.check)
                        : unlocked
                            ? Text('${index + 1}')
                            : const Icon(Icons.lock_outline),
                  ),
                  title: Text(lesson.title),
                  subtitle: Text(
                    '$stage • ${_companyName(lesson.companyKey)} • ${lesson.xp} XP'
                    '${unlocked ? '' : ' • Finish the previous lesson first'}',
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
                              builder: (_) => _FoundationLessonScreen(
                                lesson: lesson,
                                stage: stage,
                              ),
                            ),
                          ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  static String _stageFor(int index, int total) {
    if (total <= 1) return 'Independent';
    final ratio = (index + 1) / total;
    if (ratio <= 0.40) return 'Guided';
    if (ratio <= 0.75) return 'Assisted';
    return 'Independent';
  }

  static String _companyName(String key) {
    switch (key) {
      case 'saas':
        return 'SaaS';
      case 'bank':
        return 'Bank';
      case 'hospital':
        return 'Hospital';
      case 'logistics':
        return 'Logistics';
      default:
        return 'E-commerce';
    }
  }
}

class _IndependenceLegend extends StatelessWidget {
  const _IndependenceLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        Chip(
          avatar: Icon(Icons.school_outlined, size: 18),
          label: Text('Guided: learn + example'),
        ),
        Chip(
          avatar: Icon(Icons.lightbulb_outline, size: 18),
          label: Text('Assisted: try with hints'),
        ),
        Chip(
          avatar: Icon(Icons.workspace_premium_outlined, size: 18),
          label: Text('Independent: solve first'),
        ),
      ],
    );
  }
}

class _FoundationLessonScreen extends ConsumerStatefulWidget {
  const _FoundationLessonScreen({
    required this.lesson,
    required this.stage,
  });

  final FoundationLesson lesson;
  final String stage;

  @override
  ConsumerState<_FoundationLessonScreen> createState() =>
      _FoundationLessonScreenState();
}

class _FoundationLessonScreenState
    extends ConsumerState<_FoundationLessonScreen> {
  String _answer = '';
  int _hints = 0;
  int _failed = 0;
  bool _solutionViewed = false;
  bool _completed = false;
  bool _showWorkedExample = false;
  String? _feedback;

  FoundationLesson get item => widget.lesson;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(gameProgressProvider);
    final rewardId = 'academy:${item.id}';
    final alreadyRewarded = progress.rewardedLearningIds.contains(rewardId);
    final done = _completed || alreadyRewarded;
    final independent = widget.stage == 'Independent';
    final showExample = !independent || _showWorkedExample;

    return Scaffold(
      appBar: AppBar(title: Text(item.trackTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${widget.stage} • Lesson ${item.order} • Up to ${item.xp} XP',
            ),
            if (independent) ...[
              const SizedBox(height: 10),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Independent stage: try the company problem before opening the worked example, hints or solution. This is the bridge to real analyst work.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _LessonBlock(
              title: 'Learn the concept',
              icon: Icons.school_outlined,
              body: item.explanation,
            ),
            _LessonBlock(
              title: 'Real-world company scenario',
              icon: Icons.business_center_outlined,
              body: item.scenario,
            ),
            if (showExample)
              _LessonBlock(
                title: 'Worked example',
                icon: Icons.calculate_outlined,
                body: item.workedExample,
              )
            else
              Card(
                child: ListTile(
                  leading: const Icon(Icons.visibility_off_outlined),
                  title: const Text('Worked example hidden'),
                  subtitle: const Text(
                    'Try the independent question first. Open the example only if you need a refresher.',
                  ),
                  trailing: const Icon(Icons.visibility_outlined),
                  onTap: () => setState(() => _showWorkedExample = true),
                ),
              ),
            const SizedBox(height: 10),
            Text(item.question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final option in item.options)
              Card(
                child: ListTile(
                  leading: Icon(
                    _answer == option
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  title: Text(option),
                  selected: _answer == option,
                  onTap: done
                      ? null
                      : () => setState(() {
                            _answer = option;
                            _feedback = null;
                          }),
                ),
              ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: done ? null : _submit,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(done ? 'Completed' : 'Check answer'),
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
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3-level hints',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      independent
                          ? 'Hints are still available, but use them only after a real attempt.'
                          : 'Hints become more specific as you reveal them.',
                    ),
                    for (var i = 0; i < _hints; i++) ...[
                      const SizedBox(height: 6),
                      Text('Hint ${i + 1}: ${item.hints[i]}'),
                    ],
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: done || _hints >= item.hints.length
                          ? null
                          : () => setState(() => _hints++),
                      icon: const Icon(Icons.lightbulb_outline),
                      label: Text(
                        _hints < item.hints.length
                            ? 'Reveal hint ${_hints + 1}'
                            : 'All hints revealed',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SolutionRevealCard(
              solution: item.solution,
              revealed: _solutionViewed,
              penaltyApplies: !alreadyRewarded && !_completed,
              onReveal: _solutionViewed
                  ? null
                  : () => setState(() => _solutionViewed = true),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_answer.isEmpty) {
      setState(() => _feedback = 'Choose an answer first.');
      return;
    }
    if (_answer != item.correctAnswer) {
      setState(() {
        _failed++;
        _feedback =
            'Not yet. Re-read the company situation, then use a hint only if you need it.';
      });
      return;
    }

    final score =
        (100 - _hints * 10 - _failed * 10).clamp(40, 100).toInt();
    final earnedXp =
        await ref.read(gameProgressProvider.notifier).awardLearningXp(
              rewardId: 'academy:${item.id}',
              baseXp: item.xp,
              score: score,
              solutionViewed: _solutionViewed,
            );
    await ref.read(masteryRepositoryProvider).recordAttempt(
          item.skillKey,
          score,
        );
    await ref.read(taskPerformanceRepositoryProvider).record(
          id: item.id,
          title: item.title,
          skillKey: item.skillKey,
          difficulty: widget.stage,
          score: score,
          mode: 'foundation_academy',
          companyKey: item.companyKey,
        );
    ref.invalidate(skillProfileProvider);
    ref.invalidate(portfolioSnapshotProvider);
    ref.invalidate(jobReadinessProvider);

    if (!mounted) return;
    setState(() {
      _completed = true;
      _feedback =
          'Correct. Score: $score/100. XP earned: $earnedXp.${_solutionViewed ? ' Solution used: 5 XP deducted from this lesson reward.' : ''}';
    });
  }
}

class _LessonBlock extends StatelessWidget {
  const _LessonBlock({
    required this.title,
    required this.icon,
    required this.body,
  });

  final String title;
  final IconData icon;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 5),
                  SelectableText(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
