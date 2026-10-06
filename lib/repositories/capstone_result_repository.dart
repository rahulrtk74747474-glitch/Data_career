import '../data/app_database.dart';
import '../models/capstone_result.dart';
import '../services/capstone_scoring_service.dart';
import 'evidence_repository.dart';

class CapstoneResultRepository {
  const CapstoneResultRepository(this._database);

  final AppDatabase _database;

  Future<CapstoneResult?> load(String capstoneId) async {
    final db = await _database.database;
    final rows = await db.query(
      'capstone_results',
      where: 'capstone_id = ?',
      whereArgs: [capstoneId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CapstoneResult.fromMap(rows.first);
  }

  Future<void> save({
    required String capstoneId,
    required String title,
    required CapstoneScore score,
  }) async {
    final db = await _database.database;
    final now = DateTime.now().toUtc();

    await db.transaction((txn) async {
      await txn.insert(
        'capstone_results',
        {
          'capstone_id': capstoneId,
          'completed_at': now.toIso8601String(),
          'total_score': score.total,
          'cleaning_score': score.cleaning,
          'sql_score': score.sql,
          'statistics_score': score.statistics,
          'kpi_score': score.kpi,
          'dashboard_score': score.dashboard,
          'recommendation_score': score.recommendation,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await EvidenceRepository.insertWithExecutor(
        txn,
        sourceType: 'capstone',
        sourceId: capstoneId,
        title: title,
        skillKey: 'business',
        score: score.total,
        mode: 'graduation_capstone',
        companyKey: 'cross_company',
        completedAt: now,
      );
    });
  }

  Future<void> resetAll() async {
    final db = await _database.database;
    await db.delete('capstone_results');
  }
}
