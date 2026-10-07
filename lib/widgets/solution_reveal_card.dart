import 'package:flutter/material.dart';

import '../services/learning_reward_service.dart';

class SolutionRevealCard extends StatelessWidget {
  const SolutionRevealCard({
    super.key,
    required this.solution,
    required this.revealed,
    required this.onReveal,
    this.penaltyApplies = true,
  });

  final String solution;
  final bool revealed;
  final VoidCallback? onReveal;
  final bool penaltyApplies;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_center_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stuck? View the solution',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              penaltyApplies
                  ? 'Use the hints first if you can. Opening the full solution reduces this task’s earned XP by ${LearningRewardService.solutionPenaltyXp} XP.'
                  : 'This attempt has no remaining XP reward at risk, so you can review the solution freely.',
            ),
            const SizedBox(height: 10),
            if (!revealed)
              OutlinedButton.icon(
                onPressed: onReveal,
                icon: const Icon(Icons.visibility_outlined),
                label: Text(
                  penaltyApplies
                      ? 'Show solution (-${LearningRewardService.solutionPenaltyXp} XP)'
                      : 'Show solution',
                ),
              )
            else ...[
              const Divider(),
              SelectableText(solution),
            ],
          ],
        ),
      ),
    );
  }
}
