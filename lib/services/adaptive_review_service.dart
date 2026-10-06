import '../models/analyst_task.dart';
import '../models/skill_mastery.dart';

class ReviewItem {
  const ReviewItem({
    required this.task,
    required this.skill,
    required this.priority,
    required this.reason,
  });

  final AnalystTask task;
  final SkillMastery skill;
  final int priority;
  final String reason;
}

class AdaptiveReviewService {
  const AdaptiveReviewService._();

  static List<ReviewItem> buildQueue({
    required List<SkillMastery> skills,
    required List<AnalystTask> tasks,
    required DateTime now,
  }) {
    final items = <ReviewItem>[];

    for (final skill in skills) {
      if (skill.attempts == 0) continue;

      final due = skill.isDue(now);
      if (!due && !skill.isWeak) continue;

      final candidates =
          tasks.where((task) => task.skillKey == skill.skillKey).toList();
      if (candidates.isEmpty) continue;

      candidates.sort(
        (a, b) => _difficultyRank(a.difficulty)
            .compareTo(_difficultyRank(b.difficulty)),
      );

      final weakness = (100 - skill.mastery).round();
      final priority = (due ? 2000 : 1000) + weakness;
      final reason = due
          ? 'Due now • mastery ${skill.mastery.toStringAsFixed(0)}%'
          : 'Weak topic • mastery ${skill.mastery.toStringAsFixed(0)}%';

      items.add(
        ReviewItem(
          task: candidates.first,
          skill: skill,
          priority: priority,
          reason: reason,
        ),
      );
    }

    items.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;
      return a.skill.mastery.compareTo(b.skill.mastery);
    });

    return items;
  }

  static List<AnalystTask> recommendTasks({
    required List<SkillMastery> skills,
    required List<AnalystTask> tasks,
    required Set<String> completedTaskIds,
    int limit = 3,
  }) {
    final remaining = tasks
        .where((task) => !completedTaskIds.contains(task.id))
        .toList();
    final orderedSkills = [...skills]
      ..sort((a, b) => a.mastery.compareTo(b.mastery));

    final result = <AnalystTask>[];
    for (final skill in orderedSkills) {
      for (final task in remaining.where(
        (candidate) => candidate.skillKey == skill.skillKey,
      )) {
        if (result.any((existing) => existing.id == task.id)) continue;
        result.add(task);
        if (result.length >= limit) return result;
      }
    }

    for (final task in remaining) {
      if (result.any((existing) => existing.id == task.id)) continue;
      result.add(task);
      if (result.length >= limit) break;
    }
    return result;
  }

  static int _difficultyRank(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'intermediate':
        return 1;
      case 'advanced':
        return 2;
      default:
        return 0;
    }
  }
}
