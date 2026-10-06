import '../data/app_database.dart';
import '../models/analyst_task.dart';
import '../models/task_performance.dart';

class TaskPerformanceRepository {
  const TaskPerformanceRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<void> recordTask(AnalystTask task, int score) {
    return record(
      id: task.id,
      title: task.title,
      skillKey: task.skillKey,
      difficulty: task.difficulty,
      score: score,
    );
  }

  Future<void> record({
    required String id,
    required String title,
    required String skillKey,
    required String difficulty,
    required int score,
  }) async {
    final db = await _appDatabase.database;
    final normalizedScore = score.clamp(0, 100).toInt();

    await db.transaction((txn) async {
      final rows = await txn.query(
        'task_performance',
        where: 'task_id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) {
        await txn.insert('task_performance', {
          'task_id': id,
          'title': title,
          'skill_key': skillKey,
          'difficulty': difficulty,
          'best_score': normalizedScore,
          'attempts': 1,
          'last_completed_at': DateTime.now().toUtc().toIso8601String(),
        });
        return;
      }

      final existing = rows.first;
      final currentBest = (existing['best_score'] as num).toInt();
      final attempts = (existing['attempts'] as num).toInt();
      await txn.update(
        'task_performance',
        {
          'title': title,
          'skill_key': skillKey,
          'difficulty': difficulty,
          'best_score':
              normalizedScore > currentBest ? normalizedScore : currentBest,
          'attempts': attempts + 1,
          'last_completed_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'task_id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<List<TaskPerformance>> loadAll() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'task_performance',
      orderBy: 'best_score DESC, last_completed_at DESC',
    );
    return rows.map(TaskPerformance.fromMap).toList();
  }

  Future<void> resetAll() async {
    final db = await _appDatabase.database;
    await db.delete('task_performance');
  }
}
