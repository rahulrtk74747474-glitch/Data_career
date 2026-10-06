import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/career_progression_service.dart';
import '../game/game_progress.dart';
import '../game/game_providers.dart';

class PerformanceReviewScreen extends ConsumerWidget {
  const PerformanceReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final review = ref.watch(promotionReviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Performance Review')),
      body: SafeArea(
        child: review.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not calculate your review.\n$error'),
          ),
          data: (result) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                progress.isTopRole
                    ? 'Top career level reached'
                    : '${progress.role} → ${GameProgress.roleNames[result.targetLevel]}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                progress.isTopRole
                    ? 'You have reached Head of Analytics.'
                    : 'Promotions require evidence, not XP alone. Meet every requirement, then submit this review.',
              ),
              const SizedBox(height: 16),
              if (!progress.isTopRole)
                for (final criterion in result.criteria)
                  _CriterionCard(criterion: criterion),
              if (!progress.isTopRole) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: result.passed
                      ? () => _promote(context, ref, progress)
                      : null,
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: const Text('Approve promotion'),
                ),
                if (!result.passed) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Incomplete items are your exact promotion blockers.',
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promote(
    BuildContext context,
    WidgetRef ref,
    GameProgress before,
  ) async {
    await ref.read(gameProgressProvider.notifier).promote();
    ref.invalidate(promotionReviewProvider);
    ref.invalidate(careerTasksProvider);
    ref.invalidate(dailyChallengeProvider);

    if (!context.mounted) return;
    final after = ref.read(gameProgressProvider);
    final companyChanged = before.companyKey != after.companyKey;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          companyChanged
              ? 'Promoted to ${after.role}. ${after.companyName} is now unlocked.'
              : 'Promoted to ${after.role}.',
        ),
      ),
    );
  }
}

class _CriterionCard extends StatelessWidget {
  const _CriterionCard({required this.criterion});

  final PromotionCriterion criterion;

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
