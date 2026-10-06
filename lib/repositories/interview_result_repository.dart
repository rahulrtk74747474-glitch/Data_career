import '../data/app_database.dart';
import '../models/interview_result.dart';
import 'evidence_repository.dart';

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
    String companyKey = 'career',
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
      final now = DateTime.now().toUtc();

      if (rows.isEmpty) {
        await txn.insert('interview_results', {
          'round_key': roundKey,
          'completed_at': now.toIso8601String(),
          'best_score': normalized,
          'latest_score': normalized,
          'attempts': 1,
          'last_mode': timed ? 'timed' : 'untimed',
        });
      } else {
        final existing = rows.first;
        final best = (existing['best_score'] as num).toInt();
        final attempts = (existing['attempts'] as num).toInt();
        await txn.update(
          'interview_results',
          {
            'completed_at': now.toIso8601String(),
            'best_score': normalized > best ? normalized : best,
            'latest_score': normalized,
            'attempts': attempts + 1,
            'last_mode': timed ? 'timed' : 'untimed',
          },
          where: 'round_key = ?',
          whereArgs: [roundKey],
        );
      }

      final skillKey = roundKey.contains('sql')
          ? 'sql'
          : roundKey.contains('stat')
              ? 'statistics'
              : 'business';
      await EvidenceRepository.insertWithExecutor(
        txn,
        sourceType: 'interview',
        sourceId: roundKey,
        title: 'Interview • $roundKey',
        skillKey: skillKey,
        score: normalized,
        mode: timed ? 'timed' : 'untimed',
        companyKey: companyKey,
        completedAt: now,
      );
    });
  }

  Future<void> resetAll() async {
    final db = await _appDatabase.database;
    await db.delete('interview_results');
  }
}
