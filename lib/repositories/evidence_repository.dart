import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../models/evidence_attempt.dart';

class EvidenceRepository {
  const EvidenceRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  static Future<void> insertWithExecutor(
    DatabaseExecutor executor, {
    required String sourceType,
    required String sourceId,
    required String title,
    required String skillKey,
    required int score,
    required String mode,
    required String companyKey,
    DateTime? completedAt,
  }) async {
    await executor.insert('evidence_attempts', {
      'source_type': sourceType,
      'source_id': sourceId,
      'title': title,
      'skill_key': skillKey,
      'score': score.clamp(0, 100).toInt(),
      'mode': mode,
      'company_key': companyKey,
      'completed_at':
          (completedAt ?? DateTime.now().toUtc()).toIso8601String(),
    });
  }

  Future<void> record({
    required String sourceType,
    required String sourceId,
    required String title,
    required String skillKey,
    required int score,
    required String mode,
    required String companyKey,
  }) async {
    final db = await _appDatabase.database;
    await insertWithExecutor(
      db,
      sourceType: sourceType,
      sourceId: sourceId,
      title: title,
      skillKey: skillKey,
      score: score,
      mode: mode,
      companyKey: companyKey,
    );
  }

  Future<List<EvidenceAttempt>> loadAll({int? limit}) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'evidence_attempts',
      orderBy: 'attempt_id DESC',
      limit: limit,
    );
    return rows.map(EvidenceAttempt.fromMap).toList();
  }

  Future<void> resetAll() async {
    final db = await _appDatabase.database;
    await db.delete('evidence_attempts');
  }
}
