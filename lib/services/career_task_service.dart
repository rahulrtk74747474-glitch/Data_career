import '../features/game/game_progress.dart';
import '../models/analyst_task.dart';

class CareerTaskService {
  const CareerTaskService._();

  static List<AnalystTask> visibleTasks({
    required GameProgress progress,
    required List<AnalystTask> tasks,
    int limit = 6,
  }) {
    final companyTasks = tasks.where(
      (task) =>
          task.companyKey == progress.companyKey &&
          task.minCareerLevel <= progress.careerLevel,
    );

    final allowedDifficulties = _allowedDifficulties(progress.careerLevel);
    var candidates = companyTasks
        .where((task) => allowedDifficulties.contains(task.difficulty))
        .toList();

    if (candidates.isEmpty) {
      candidates = companyTasks.toList();
    }

    candidates.sort((a, b) {
      final aCompleted = progress.completedTaskIds.contains(a.id);
      final bCompleted = progress.completedTaskIds.contains(b.id);
      if (aCompleted != bCompleted) return aCompleted ? 1 : -1;
      return _difficultyRank(a.difficulty)
          .compareTo(_difficultyRank(b.difficulty));
    });

    return candidates.take(limit).toList();
  }

  static Set<String> _allowedDifficulties(int careerLevel) {
    switch (careerLevel) {
      case 0:
        return const {'Beginner'};
      case 1:
        return const {'Beginner', 'Intermediate'};
      case 2:
        return const {'Intermediate'};
      case 3:
        return const {'Intermediate', 'Advanced'};
      default:
        return const {'Advanced', 'Intermediate'};
    }
  }

  static int _difficultyRank(String difficulty) {
    switch (difficulty) {
      case 'Advanced':
        return 2;
      case 'Intermediate':
        return 1;
      default:
        return 0;
    }
  }
}
