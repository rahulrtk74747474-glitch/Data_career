import '../data/app_database.dart';
import '../models/boss_case_result.dart';
import '../models/evidence_attempt.dart';
import '../models/portfolio_snapshot.dart';
import '../models/task_performance.dart';

class PortfolioRepository {
  const PortfolioRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<PortfolioSnapshot> load() async {
    final db = await _appDatabase.database;

    final taskRows = await db.query(
      'task_performance',
      orderBy: 'best_score DESC, last_completed_at DESC',
    );
    final bossRows = await db.query(
      'boss_case_results',
      orderBy: 'total_score DESC, completed_at DESC',
    );
    final attemptRows = await db.query(
      'evidence_attempts',
      orderBy: 'attempt_id DESC',
    );

    return PortfolioSnapshot(
      taskPerformances: taskRows.map(TaskPerformance.fromMap).toList(),
      bossCases: bossRows.map(BossCaseResult.fromMap).toList(),
      attempts: attemptRows.map(EvidenceAttempt.fromMap).toList(),
    );
  }
}
