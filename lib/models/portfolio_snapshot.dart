import 'boss_case_result.dart';
import 'evidence_attempt.dart';
import 'task_performance.dart';

class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.taskPerformances,
    required this.bossCases,
    required this.attempts,
  });

  final List<TaskPerformance> taskPerformances;
  final List<BossCaseResult> bossCases;
  final List<EvidenceAttempt> attempts;

  int get evidenceCount => taskPerformances.length + bossCases.length;

  int get attemptCount => attempts.length;

  double get averageBestScore {
    if (taskPerformances.isEmpty) return 0;
    final total = taskPerformances.fold<int>(
      0,
      (sum, item) => sum + item.bestScore,
    );
    return total / taskPerformances.length;
  }

  double get averageAttemptScore {
    if (attempts.isEmpty) return 0;
    final total = attempts.fold<int>(
      0,
      (sum, item) => sum + item.score,
    );
    return total / attempts.length;
  }

  TaskPerformance? get strongestTask {
    if (taskPerformances.isEmpty) return null;
    final sorted = [...taskPerformances]
      ..sort((a, b) => b.bestScore.compareTo(a.bestScore));
    return sorted.first;
  }
}
