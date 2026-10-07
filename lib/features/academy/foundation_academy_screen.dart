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
    return Scaffold(
      appBar: AppBar(title: const Text('Zero-to-Analyst Academy')),
      body: SafeArea(
        child: lessons.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load beginner lessons.\n$error'),
          ),
          data: (items) {
            final tracks = <String, String>{};
            for (final item in items) {
              tracks[item.trackKey] = item.trackTitle;
            }
            final filtered = _track == 'all'
                ? items
                : items.where((item) => item.trackKey == _track).toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Start here if you know nothing yet',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Learn one idea at a time through realistic company work: explanation, worked example, mini task, three hints and an optional full solution.',
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _track == 'all',
                        onSelected: (_) => setState(() => _track = 'all'),
                      ),
                      const SizedBox(width: 6),
                      for (final entry in tracks.entries) ...[
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _track == entry.key,
                          onSelected: (_) => setState(() => _track = entry.key),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final item in filtered)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(item.order.toString())),
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.trackTitle} • ${_companyName(item.companyKey)} • ${item.xp} XP',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _FoundationLessonScreen(lesson: item),
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

class _FoundationLessonScreen extends ConsumerStatefulWidget {
  const _FoundationLessonScreen({required this.lesson});
  final FoundationLesson lesson;

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
  String? _feedback;

  FoundationLesson get item => widget.lesson;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(gameProgressProvider);
    final rewardId = 'academy:${item.id}';
    final alreadyRewarded = progress.rewardedLearningIds.contains(rewardId);

    return Scaffold(
      appBar: AppBar(title: Text(item.trackTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Lesson ${item.order} • Up to ${item.xp} XP'),
            const SizedBox(height: 16),
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
            _LessonBlock(
              title: 'Worked example',
              icon: Icons.calculate_outlined,
              body: item.workedExample,
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
                  onTap: _completed
                      ? null
                      : () => setState(() => _answer = option),
                ),
              ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _completed ? null : _submit,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(_completed ? 'Completed' : 'Check answer'),
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
                    for (var i = 0; i < _hints; i++) ...[
                      const SizedBox(height: 6),
                      Text('Hint ${i + 1}: ${item.hints[i]}'),
                    ],
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _completed || _hints >= item.hints.length
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
        _feedback = 'Not yet. Use the hints, review the example, and try again.';
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
    await ref.read(masteryRepositoryProvider).recordAttempt(item.skillKey, score);
    await ref.read(taskPerformanceRepositoryProvider).record(
          id: item.id,
          title: item.title,
          skillKey: item.skillKey,
          difficulty: 'Foundation',
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
