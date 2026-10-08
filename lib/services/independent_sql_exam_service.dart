// ignore_for_file: prefer_interpolation_to_compose_strings
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import 'sql_result_grader.dart';
import 'sql_runner.dart';

class IndependentSqlResult {
  const IndependentSqlResult({
    required this.correct, required this.feedback,
    required this.attempts, required this.verifiedOnChangedData,
  });
  final bool correct;
  final String feedback;
  final int attempts;
  final bool verifiedOnChangedData;
}

/// An unseen-schema, no-hint practical challenge, distinct from the flagship.
/// Training assessment, not a real hiring credential.
class IndependentSqlExamService {
  const IndependentSqlExamService(this._database);
  final AppDatabase _database;
  static const key = 'dataquest_sql_independent_exam_v1';
  static const instructions =
      'A separate revenue operations company ingests order updates. '
      'Using dq_exam_latest, calculate completed net revenue by region. '
      'Return exactly region and SUM(net_revenue) AS revenue. '
      'Use the latest order event, not all duplicate ingestions. '
      'Do not hardcode the result.';
  static const schema = <String>[
    '''CREATE TABLE IF NOT EXISTS dq_exam_event (
      event_id TEXT PRIMARY KEY, order_id TEXT NOT NULL,
      region TEXT NOT NULL, status TEXT NOT NULL,
      gross_amount INTEGER NOT NULL, refunded_amount INTEGER NOT NULL,
      ingested_at TEXT NOT NULL
    )''',
    '''CREATE VIEW IF NOT EXISTS dq_exam_latest AS
      SELECT order_id, region, status,
       CASE WHEN status = 'completed'
         THEN MAX(0, gross_amount - refunded_amount)
         ELSE 0 END AS net_revenue
      FROM (
        SELECT *, ROW_NUMBER() OVER (
          PARTITION BY order_id ORDER BY ingested_at DESC, event_id DESC
        ) AS seq FROM dq_exam_event
      ) WHERE seq = 1''',
  ];
  static const _source = <List<Object>>[
    ['X01', 'Q01', 'North', 'completed', 1200, 100, '2026-09-01'],
    ['X02', 'Q02', 'North', 'completed', 900, 0, '2026-09-01'],
    ['X03', 'Q03', 'South', 'completed', 2500, 300, '2026-09-01'],
    ['X04', 'Q04', 'South', 'cancelled', 700, 0, '2026-09-01'],
    ['X05', 'Q05', 'West', 'completed', 1850, 250, '2026-09-01'],
    ['X06', 'Q06', 'West', 'completed', 600, 0, '2026-09-01'],
    ['X07', 'Q03', 'South', 'completed', 2650, 300, '2026-09-02'],
    ['X08', 'Q02', 'North', 'completed', 900, 0, '2026-09-02'],
    ['X09', 'Q06', 'West', 'completed', 600, 0, '2026-09-03'],
  ];
  static const referenceQuery =
      "SELECT region, SUM(net_revenue) AS revenue FROM dq_exam_latest "
      "WHERE status = 'completed' GROUP BY region ORDER BY region";

  Future<void> ensureReady() async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final statement in schema) {
        await txn.execute(statement);
      }
      final existing = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT COUNT(*) FROM dq_exam_event')) ?? 0;
      if (existing != 0) return;
      for (final row in _source) {
        await txn.insert('dq_exam_event', {
          'event_id': row[0], 'order_id': row[1], 'region': row[2],
          'status': row[3], 'gross_amount': row[4],
          'refunded_amount': row[5], 'ingested_at': row[6],
        }, conflictAlgorithm: ConflictAlgorithm.abort);
      }
    });
  }

  Future<List<Map<String, Object?>>> preview() async {
    await ensureReady();
    return (await (await _database.database).query(
      'dq_exam_event', orderBy: 'event_id',
    ));
  }

  Future<IndependentSqlResult> assess(String submitted) async {
    await ensureReady();
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt(key + ':attempts') ?? 0) + 1;
    await prefs.setInt(key + ':attempts', attempts);
    final query = submitted.trim();
    // Table name in the FROM clause is necessary but not sufficient.
    if (!RegExp(r'\bfrom\s+dq_exam_latest\b', caseSensitive: false)
        .hasMatch(query)) {
      return IndependentSqlResult(
        correct: false,
        feedback: 'Use dq_exam_latest; raw event rows contain late updates.',
        attempts: attempts, verifiedOnChangedData: false,
      );
    }
    final run = await SqlRunner(_database).runReadOnly(query);
    if (!run.isSuccess) {
      return IndependentSqlResult(
        correct: false, feedback: run.error ?? 'SQL did not run',
        attempts: attempts, verifiedOnChangedData: false,
      );
    }
    final expected = await (await _database.database).rawQuery(referenceQuery);
    final grade = SqlResultGrader.grade(
      actualRows: run.rows,
      expectedRows: [for (final row in expected) Map<String, dynamic>.from(row)],
      truncated: run.truncated,
    );
    if (!grade.isCorrect) {
      return IndependentSqlResult(
        correct: false, feedback: grade.feedback,
        attempts: attempts, verifiedOnChangedData: false,
      );
    }
    SqlResultGrade? holdout;
    final db = await _database.database;
    try {
      await db.transaction((txn) async {
        await txn.rawUpdate(
          'UPDATE dq_exam_event SET gross_amount = gross_amount + 173 '
          "WHERE event_id = 'X01'",
        );
        final actual = await txn.rawQuery(query);
        final expectedRows = await txn.rawQuery(referenceQuery);
        holdout = SqlResultGrader.grade(
          actualRows: actual,
          expectedRows: [
            for (final row in expectedRows) Map<String, dynamic>.from(row),
          ],
        );
        throw const _RollbackExam();
      });
    } on _RollbackExam {
      // Verified result was computed before rollback.
    }
    final correct = holdout?.isCorrect ?? false;
    if (correct) {
      await prefs.setBool(key + ':passed', true);
      await prefs.setString(key + ':query', query);
    }
    return IndependentSqlResult(
      correct: correct,
      feedback: correct
          ? 'Pass: correct SQL on this independent schema and changed records. '
              'This is a synthetic training assessment, not a job qualification.'
          : 'Numbers match the visible snapshot, but the query fails when '
              'an order amount changes. Compute revenue from data, not constants.',
      attempts: attempts, verifiedOnChangedData: correct,
    );
  }

  Future<bool> hasPassed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key + ':passed') ?? false;
  }
}

class _RollbackExam {
  const _RollbackExam();
}
