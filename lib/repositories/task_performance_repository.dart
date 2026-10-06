import '../data/app_database.dart';
import '../models/analyst_task.dart';
import '../models/task_performance.dart';
import 'evidence_repository.dart';

class TaskPerformanceRepository {
  const TaskPerformanceRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<void> recordTask(
    AnalystTask task,
    int score, {
    String mode = 'career',
  }) {
    return record(
      id: task.id,
      title: task.title,
      skillKey: task.skillKey,
      difficulty: task.difficulty,
      score: score,
      mode: mode,
      companyKey: task.companyKey,
    );
  }

  Future<void> record({
    required String id,
    required String title,
    required String skillKey,
    required String difficulty,
    required int score,
    String mode = 'practice',
    String companyKey = 'training',
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
      final now = DateTime.now().toUtc();

      if (rows.isEmpty) {
        await txn.insert('task_performance', {
          'task_id': id,
          'title': title,
          'skill_key': skillKey,
          'difficulty': difficulty,
          'best_score': normalizedScore,
          'attempts': 1,
          'last_completed_at': now.toIso8601String(),
        });
      } else {
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
            'last_completed_at': now.toIso8601String(),
          },
          where: 'task_id = ?',
          whereArgs: [id],
        );
      }

      await EvidenceRepository.insertWithExecutor(
        txn,
        sourceType: 'task',
        sourceId: id,
        title: title,
        skillKey: skillKey,
        score: normalizedScore,
        mode: mode,
        companyKey: companyKey,
        completedAt: now,
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
