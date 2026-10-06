import 'boss_case_result.dart';
import 'task_performance.dart';

class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.taskPerformances,
    required this.bossCases,
  });

  final List<TaskPerformance> taskPerformances;
  final List<BossCaseResult> bossCases;

  int get evidenceCount => taskPerformances.length + bossCases.length;

  double get averageBestScore {
    if (taskPerformances.isEmpty) return 0;
    final total = taskPerformances.fold<int>(
      0,
      (sum, item) => sum + item.bestScore,
    );
    return total / taskPerformances.length;
  }

  TaskPerformance? get strongestTask {
    if (taskPerformances.isEmpty) return null;
    final sorted = [...taskPerformances]
      ..sort((a, b) => b.bestScore.compareTo(a.bestScore));
    return sorted.first;
  }
}
