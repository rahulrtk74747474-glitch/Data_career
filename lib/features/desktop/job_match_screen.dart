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
