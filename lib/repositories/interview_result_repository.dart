import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../models/interview_result.dart';

class InterviewResultRepository {
  const InterviewResultRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<InterviewResult>> loadAll() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'interview_results',
      orderBy: 'best_score DESC, round_key',
    );
    return rows.map(InterviewResult.fromMap).toList();
  }

  Future<void> save({
    required String roundKey,
    required int score,
    required bool timed,
  }) async {
    final db = await _appDatabase.database;
    final normalized = score.clamp(0, 100).toInt();

    await db.transaction((txn) async {
      final rows = await txn.query(
        'interview_results',
        where: 'round_key = ?',
        whereArgs: [roundKey],
        limit: 1,
      );
      final now = DateTime.now().toUtc().toIso8601String();

      if (rows.isEmpty) {
        await txn.insert('interview_results', {
          'round_key': roundKey,
          'completed_at': now,
          'best_score': normalized,
          'latest_score': normalized,
          'attempts': 1,
          'last_mode': timed ? 'timed' : 'untimed',
        });
        return;
      }

      final existing = rows.first;
      final best = (existing['best_score'] as num).toInt();
      final attempts = (existing['attempts'] as num).toInt();
      await txn.update(
        'interview_results',
        {
          'completed_at': now,
          'best_score': normalized > best ? normalized : best,
          'latest_score': normalized,
          'attempts': attempts + 1,
          'last_mode': timed ? 'timed' : 'untimed',
        },
        where: 'round_key = ?',
        whereArgs: [roundKey],
      );
    });
  }

  Future<void> resetAll() async {
    final db = await _appDatabase.database;
    await db.delete('interview_results');
  }
}
