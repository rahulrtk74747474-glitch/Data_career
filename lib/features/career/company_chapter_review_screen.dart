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
        child: review.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not calculate company review.\n$error'),
          ),
          data: (result) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                result.finalAvailableChapter
                    ? progress.companyName
                    : '${progress.companyName} → '
                        '${GameProgress.companyNames[result.targetChapter]}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                result.finalAvailableChapter
                    ? 'Hospital Analytics is the final company chapter available in Phase 7. Your role remains ${progress.role}; later company chapters can continue independently.'
                    : 'Company progression is separate from promotions. Meet every evidence gate to unlock the next industry chapter while keeping your current career role.',
              ),
              const SizedBox(height: 16),
              if (!result.finalAvailableChapter)
                for (final criterion in result.criteria)
                  _CriterionCard(criterion: criterion),
              if (!result.finalAvailableChapter) ...[
                const SizedBox(height: 12),
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
                    'Incomplete items above are the exact company-unlock blockers.',
                  ),
                ],
              ] else ...[
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.lock_clock_outlined),
                    title: Text('Next chapter: Logistics Network Co.'),
                    subtitle: Text(
                      'Reserved for Phase 8 so you cannot enter an empty chapter.',
                    ),
                  ),
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

    ref.invalidate(companyChapterReviewProvider);
    ref.invalidate(careerTasksProvider);
    ref.invalidate(dailyChallengeProvider);
    ref.invalidate(bossCaseProvider);
    ref.invalidate(promotionReviewProvider);
    ref.invalidate(adaptiveRecommendationsProvider);

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
