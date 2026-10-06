import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/company_chapter_progression_service.dart';
import '../game/game_progress.dart';
import '../game/game_providers.dart';

class CompanyChapterReviewScreen extends ConsumerWidget {
  const CompanyChapterReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final review = ref.watch(companyChapterReviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Company Chapter Review')),
      body: SafeArea(
        child: progress.companyJourneyCompleted
            ? _JourneyCompleteView(progress: progress)
            : review.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text(
                    'Could not calculate company review.\n$error',
                  ),
                ),
                data: (result) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      result.isJourneyCompletionReview
                          ? 'Final company journey review'
                          : '${progress.companyName} → '
                              '${GameProgress.companyNames[result.targetChapter]}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.isJourneyCompletionReview
                          ? 'Logistics is the final company chapter in the current journey. Meet the final evidence gates to complete all five companies while keeping your role as ${progress.role}.'
                          : 'Company progression is separate from promotions. Meet every evidence gate to unlock the next industry chapter while keeping your current career role.',
                    ),
                    const SizedBox(height: 16),
                    for (final criterion in result.criteria)
                      _CriterionCard(criterion: criterion),
                    const SizedBox(height: 12),
                    if (result.isJourneyCompletionReview)
                      FilledButton.icon(
                        onPressed: result.passed
                            ? () => _completeJourney(context, ref)
                            : null,
                        icon: const Icon(Icons.emoji_events_outlined),
                        label: const Text('Complete company journey'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: result.passed
                            ? () => _advance(context, ref, progress)
                            : null,
                        icon: const Icon(Icons.business_center_outlined),
                        label: Text(
                          'Unlock ${GameProgress.companyNames[result.targetChapter]}',
                        ),
                      ),
                    if (!result.passed) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Incomplete items above are the exact company-review blockers.',
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _advance(
    BuildContext context,
    WidgetRef ref,
    GameProgress before,
  ) async {
    await ref.read(gameProgressProvider.notifier).advanceCompanyChapter();

    _invalidateCompanyState(ref);

    if (!context.mounted) return;
    final after = ref.read(gameProgressProvider);
    final changed =
        before.resolvedCompanyChapter != after.resolvedCompanyChapter;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          changed
              ? '${after.companyName} unlocked. Your role remains ${after.role}.'
              : 'No additional company chapter is available yet.',
        ),
      ),
    );
  }

  Future<void> _completeJourney(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await ref.read(gameProgressProvider.notifier).completeCompanyJourney();
    _invalidateCompanyState(ref);

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.emoji_events, size: 42),
        title: const Text('Company journey complete'),
        content: const Text(
          'You completed the current five-company analytics journey: e-commerce, SaaS, banking, hospital operations and logistics. Your role remains Head of Analytics and all practice modes stay available.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Continue practicing'),
          ),
        ],
      ),
    );
  }

  void _invalidateCompanyState(WidgetRef ref) {
    ref.invalidate(companyChapterReviewProvider);
    ref.invalidate(careerTasksProvider);
    ref.invalidate(dailyChallengeProvider);
    ref.invalidate(bossCaseProvider);
    ref.invalidate(promotionReviewProvider);
    ref.invalidate(adaptiveRecommendationsProvider);
    ref.invalidate(availableInterviewRoundsProvider);
  }
}

class _JourneyCompleteView extends StatelessWidget {
  const _JourneyCompleteView({required this.progress});

  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(Icons.emoji_events, size: 72),
        const SizedBox(height: 12),
        Text(
          'Five-company journey complete',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'You remain ${progress.role}. Company chapters are complete, but Practice Gym, Daily Challenge, Interviews, Boss Cases, Review Queue and Portfolio remain available.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        for (var index = 0;
            index < GameProgress.companyNames.length;
            index++)
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: Text(GameProgress.companyNames[index]),
              subtitle: Text('Chapter ${index + 1} completed'),
            ),
          ),
      ],
    );
  }
}

class _CriterionCard extends StatelessWidget {
  const _CriterionCard({required this.criterion});

  final CompanyChapterCriterion criterion;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          criterion.met ? Icons.check_circle : Icons.lock_outline,
        ),
        title: Text(criterion.label),
        subtitle: Text(criterion.detail),
      ),
    );
  }
}
