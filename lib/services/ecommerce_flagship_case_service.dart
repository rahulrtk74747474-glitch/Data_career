import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import 'sql_result_grader.dart';

/// The executed workday and portfolio export use these exact local SQLite rows.
class EcommerceFlagshipCaseService {
  const EcommerceFlagshipCaseService(this._database);
  final AppDatabase _database;

  static const assetPath = 'assets/content/flagship_ecommerce_case_v2.json';
  static const datasetVersion = 2;

  static const schemaStatements = <String>[
    '''CREATE TABLE IF NOT EXISTS ec_case_customers (
      customer_id TEXT PRIMARY KEY, segment TEXT NOT NULL, region TEXT NOT NULL
    )''',
    '''CREATE TABLE IF NOT EXISTS ec_case_order_events (
      event_id TEXT PRIMARY KEY, order_id TEXT NOT NULL, customer_id TEXT NOT NULL,
      status TEXT NOT NULL, gross_amount INTEGER NOT NULL,
      cogs_amount INTEGER NOT NULL, ordered_at TEXT NOT NULL,
      ingested_at TEXT NOT NULL
    )''',
    '''CREATE TABLE IF NOT EXISTS ec_case_refund_events (
      event_id TEXT PRIMARY KEY, refund_id TEXT NOT NULL, order_id TEXT NOT NULL,
      refund_amount INTEGER NOT NULL, ingested_at TEXT NOT NULL
    )''',
    '''CREATE TABLE IF NOT EXISTS ec_case_metadata (
      case_id TEXT PRIMARY KEY, dataset_version INTEGER NOT NULL
    )''',
    '''CREATE VIEW IF NOT EXISTS ec_case_clean_orders AS
      WITH latest_order_events AS (
        SELECT *, ROW_NUMBER() OVER (
          PARTITION BY order_id ORDER BY ingested_at DESC, event_id DESC
        ) AS sequence
        FROM ec_case_order_events
      ),
      latest_refund_events AS (
        SELECT *, ROW_NUMBER() OVER (
          PARTITION BY refund_id ORDER BY ingested_at DESC, event_id DESC
        ) AS sequence
        FROM ec_case_refund_events
      ),
      refunds_by_order AS (
        SELECT order_id, SUM(refund_amount) AS refund_total
        FROM latest_refund_events WHERE sequence = 1 GROUP BY order_id
      )
      SELECT o.order_id, o.customer_id, o.ordered_at, o.status,
        o.gross_amount, o.cogs_amount,
        COALESCE(r.refund_total, 0) AS refund_total,
        CASE WHEN o.status = 'completed'
          THEN MAX(0, o.gross_amount - COALESCE(r.refund_total, 0))
          ELSE 0 END AS net_revenue
      FROM latest_order_events o
      LEFT JOIN refunds_by_order r ON r.order_id = o.order_id
      WHERE o.sequence = 1''',
  ];

  static const referenceQuery =
      'SELECT c.segment, SUM(o.net_revenue) AS revenue '
      'FROM ec_case_clean_orders o '
      'JOIN ec_case_customers c ON c.customer_id = o.customer_id '
      "WHERE o.status = 'completed' "
      'GROUP BY c.segment ORDER BY c.segment';

  Future<Map<String, dynamic>> loadPack() async => Map<String, dynamic>.from(
    jsonDecode(await rootBundle.loadString(assetPath)) as Map,
  );

  /// Safe to call on every workday open. Never modifies non-case tables.
  Future<void> ensureReady() async {
    final pack = await loadPack();
    if ((pack['schemaVersion'] as num).toInt() != datasetVersion) {
      throw StateError('Unsupported e-commerce case dataset version.');
    }
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final statement in schemaStatements) {
        await txn.execute(statement);
      }
      final version = await txn.query(
        'ec_case_metadata',
        columns: ['dataset_version'],
        where: 'case_id = ?',
        whereArgs: [pack['caseId']],
        limit: 1,
      );
      if (version.isNotEmpty &&
          (version.first['dataset_version'] as num).toInt() == datasetVersion) {
        return;
      }
      for (final table in const [
        'ec_case_refund_events', 'ec_case_order_events', 'ec_case_customers',
      ]) {
        await txn.delete(table);
      }
      for (final entry in const {
        'ec_case_customers': 'customers',
        'ec_case_order_events': 'orderEvents',
        'ec_case_refund_events': 'refundEvents',
      }.entries) {
        for (final raw in pack[entry.value] as List<dynamic>) {
          await txn.insert(
            entry.key,
            Map<String, Object?>.from(raw as Map),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      }
      await txn.insert(
        'ec_case_metadata',
        <String, Object?>{
          'case_id': pack['caseId'] as String,
          'dataset_version': datasetVersion,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<EcommerceCaseAudit> audit() async {
    await ensureReady();
    final db = await _database.database;
    final row = (await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM ec_case_order_events) AS order_events,
        (SELECT COUNT(DISTINCT order_id) FROM ec_case_order_events) AS orders,
        (SELECT COUNT(*) FROM ec_case_refund_events) AS refund_events,
        (SELECT COUNT(DISTINCT refund_id) FROM ec_case_refund_events) AS refunds,
        (SELECT COALESCE(SUM(net_revenue), 0)
         FROM ec_case_clean_orders) AS net_revenue
    ''')).single;
    return EcommerceCaseAudit(
      rawOrderEvents: (row['order_events'] as num).toInt(),
      uniqueOrders: (row['orders'] as num).toInt(),
      rawRefundEvents: (row['refund_events'] as num).toInt(),
      uniqueRefunds: (row['refunds'] as num).toInt(),
      netRevenue: (row['net_revenue'] as num).toInt(),
    );
  }

  Future<Map<String, List<Map<String, Object?>>>> exportTables() async {
    await ensureReady();
    final db = await _database.database;
    final result = <String, List<Map<String, Object?>>>{};
    for (final table in const [
      'ec_case_customers', 'ec_case_order_events',
      'ec_case_refund_events', 'ec_case_clean_orders',
    ]) {
      final key = switch (table) {
        'ec_case_customers' => 'customers',
        'ec_case_order_events' => 'order_events',
        'ec_case_refund_events' => 'refund_events',
        _ => 'clean_orders',
      };
      final order = switch (key) {
        'customers' => 'customer_id',
        'order_events' => 'event_id',
        'refund_events' => 'event_id',
        _ => 'order_id',
      };
      result[key] = await db.query(table, orderBy: order);
    }
    return result;
  }

  static String get portableSchema => '${schemaStatements.join(';\n\n')};\n';

  /// Require actual FROM/JOIN references, not names pasted into comments or
  /// SQL string literals. The holdout run below is the stronger data check.
  static String? queryIntegrityWarning(String sql) {
    final executable = sql
        .replaceAll(RegExp(r'/\\*[\\s\\S]*?\\*/'), ' ')
        .replaceAll(RegExp(r'--[^\\n\\r]*'), ' ')
        .replaceAll(RegExp(r"'(?:''|[^'])*'"), "''")
        .toLowerCase();
    bool uses(String table) => RegExp(
      r'\\b(from|join)\\s+(?:main\\.)?["`\\[]?' +
          table +
          r'["`\\]]?\\b',
      caseSensitive: false,
    ).hasMatch(executable);
    if (!uses('ec_case_clean_orders') || !uses('ec_case_customers')) {
      return 'Use ec_case_clean_orders and ec_case_customers in real FROM/JOIN '
          'clauses. Text in comments or string literals does not count.';
    }
    if (sql.contains('--') || sql.contains('/*')) {
      return 'Remove SQL comments from this assessed project query.';
    }
    return null;
  }

  /// Re-run submitted SQL on an altered, isolated snapshot *inside* a
  /// transaction that is deliberately rolled back. Fixed answers matching
  /// today's example numbers cannot pass when live case data changes.
  ///
  /// This is a hidden-data-style regression check, not a proof that the query
  /// generalizes to all schemas or business scenarios.
  Future<SqlResultGrade> verifyChangedData(String submittedQuery) async {
    final warning = queryIntegrityWarning(submittedQuery);
    if (warning != null) {
      return SqlResultGrade(isCorrect: false, feedback: warning);
    }
    await ensureReady();
    final db = await _database.database;
    SqlResultGrade? result;
    try {
      await db.transaction((txn) async {
        // Both interventions affect the Consumer segment; all changes roll
        // back before the learner's database is released to other tasks.
        final ordersChanged = await txn.rawUpdate(
          'UPDATE ec_case_order_events SET gross_amount = gross_amount + 317 '
          'WHERE event_id = ?',
          ['EV001'],
        );
        final refundsChanged = await txn.rawUpdate(
          'UPDATE ec_case_refund_events SET refund_amount = refund_amount + 41 '
          'WHERE event_id = ?',
          ['RE001'],
        );
        if (ordersChanged != 1 || refundsChanged != 1) {
          throw StateError('Flagship holdout dataset does not match version 2.');
        }
        final actual = await txn.rawQuery(submittedQuery);
        final expected = await txn.rawQuery(referenceQuery);
        result = actual.length > 100
            ? const SqlResultGrade(
                isCorrect: false,
                feedback: 'Assessment query returned too many rows.',
              )
            : SqlResultGrader.grade(
                actualRows: actual,
                expectedRows: expected.map((row) => Map<String, dynamic>.from(row)).toList(),
              );
        throw const _RollbackAssessment();
      });
    } on _RollbackAssessment {
      return result!;
    }
  }

}

class EcommerceCaseAudit {
  const EcommerceCaseAudit({
    required this.rawOrderEvents,
    required this.uniqueOrders,
    required this.rawRefundEvents,
    required this.uniqueRefunds,
    required this.netRevenue,
  });
  final int rawOrderEvents;
  final int uniqueOrders;
  final int rawRefundEvents;
  final int uniqueRefunds;
  final int netRevenue;
  int get duplicateOrderEvents => rawOrderEvents - uniqueOrders;
  int get duplicateRefundEvents => rawRefundEvents - uniqueRefunds;
}

/// A deliberately thrown sentinel ensures every holdout transaction rolls back.
class _RollbackAssessment {
  const _RollbackAssessment();
}
