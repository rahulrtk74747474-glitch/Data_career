import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../models/boss_case_result.dart';
import '../services/boss_case_scoring_service.dart';
import 'evidence_repository.dart';

class BossCaseResultRepository {
  const BossCaseResultRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<BossCaseResult?> load(String caseId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'boss_case_results',
      where: 'case_id = ?',
      whereArgs: [caseId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BossCaseResult.fromMap(rows.first);
  }

  Future<void> save(
    String caseId,
    BossCaseScore score, {
    String? title,
    String companyKey = 'career',
  }) async {
    final db = await _appDatabase.database;
    final now = DateTime.now().toUtc();

    await db.transaction((txn) async {
      await txn.insert(
        'boss_case_results',
        {
          'case_id': caseId,
          'completed_at': now.toIso8601String(),
          'total_score': score.total,
          'cleaning_score': score.cleaning,
          'sql_score': score.sql,
          'kpi_score': score.kpi,
          'chart_score': score.chart,
          'recommendation_score': score.recommendation,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await EvidenceRepository.insertWithExecutor(
        txn,
        sourceType: 'boss_case',
        sourceId: caseId,
        title: title ?? caseId,
        skillKey: 'business',
        score: score.total,
        mode: 'boss_case',
        companyKey: companyKey,
        completedAt: now,
      );
    });
  }

  Future<void> resetAll() async {
    final db = await _appDatabase.database;
    await db.delete('boss_case_results');
  }
}
