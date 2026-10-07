import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/job_match_service.dart';
import '../game/game_providers.dart';

class JobMatchScreen extends ConsumerWidget {
  const JobMatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(jobRoleProfilesProvider);
    final skills = ref.watch(skillProfileProvider);
    final portfolio = ref.watch(portfolioSnapshotProvider);
    final progress = ref.watch(gameProgressProvider);

    if (roles.isLoading || skills.isLoading || portfolio.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Match')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final error = roles.error ?? skills.error ?? portfolio.error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Match')),
        body: Center(child: Text('$error')),
      );
    }

    final projectCount = progress.rewardedLearningIds
        .where((id) => id.startsWith('mission:'))
        .length;
    final evidenceCount = portfolio.value!.evidenceCount;
    final results = [
      for (final role in roles.value!)
        JobMatchService.calculate(
          role: role,
          skills: skills.value!,
          projectCount: projectCount,
          evidenceCount: evidenceCount,
        ),
    ]..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      appBar: AppBar(title: const Text('Job Match')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Which analyst role are you ready for?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Match uses demonstrated skill mastery plus project/evidence breadth. It does not use XP.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _PasteJobDescriptionScreen(),
                ),
              ),
              icon: const Icon(Icons.content_paste_search_outlined),
              label: const Text('Match a real job description'),
            ),
            const SizedBox(height: 16),
            for (final result in results)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              result.role.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${result.score}%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(result.role.description),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: result.score / 100),
                      const SizedBox(height: 10),
                      Text(
                        result.gaps.isEmpty
                            ? 'No major readiness gaps detected. Maintain skills with interviews and projects.'
                            : 'Close next: ${result.gaps.join(' • ')}',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PasteJobDescriptionScreen extends ConsumerStatefulWidget {
  const _PasteJobDescriptionScreen();

  @override
  ConsumerState<_PasteJobDescriptionScreen> createState() =>
      _PasteJobDescriptionScreenState();
}

class _PasteJobDescriptionScreenState
    extends ConsumerState<_PasteJobDescriptionScreen> {
  final _controller = TextEditingController();
  JobDescriptionMatchResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skills = ref.watch(skillProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Match Job Description')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Paste an actual job posting',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'DataQuest scans supported analyst-skill requirements locally and compares them with your demonstrated mastery. The job text stays on the device.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              minLines: 10,
              maxLines: 18,
              decoration: const InputDecoration(
                hintText:
                    'Paste the job responsibilities and requirements here…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: skills.valueOrNull == null
                  ? null
                  : () => setState(() {
                        _result = JobDescriptionMatcher.calculateDescription(
                          description: _controller.text,
                          skills: skills.valueOrNull!,
                        );
                      }),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Analyze match'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_result!.score}% skill match',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: _result!.score / 100),
                      const SizedBox(height: 12),
                      Text(
                        _result!.detectedSkills.isEmpty
                            ? 'No supported skill requirements detected.'
                            : 'Detected: ${_result!.detectedSkills.join(' • ')}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result!.gaps.isEmpty
                            ? 'No major detected skill gaps below 70%.'
                            : 'Close next: ${_result!.gaps.join(' • ')}',
                      ),
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
}
