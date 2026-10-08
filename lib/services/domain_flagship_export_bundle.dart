import 'dart:convert';

import '../data/app_database.dart';
import '../models/flagship_attempt.dart';
import '../models/job_ready_v15.dart';
import 'sql_result_grader.dart';
import 'sql_runner.dart';

/// Portable snapshots of synthetic company tables. Personal progress, emails,
/// accounts and local-device metadata are intentionally excluded.
class DomainFlagshipExportBundle {
  const DomainFlagshipExportBundle(this._database);
  final AppDatabase _database;

  static const tables = <String, List<String>>{
    'saas': ['saas_account_monthly'],
    'bank': ['bank_accounts', 'loan_portfolio', 'bank_transactions'],
    'hospital': ['hospital_daily_ops', 'hospital_capacity_forecast'],
    'logistics': [
      'logistics_shipments',
      'logistics_inventory_flow',
      'logistics_throughput_forecast',
    ],
  };

  static const referenceQueries = <String, String>{
    'saas': "SELECT segment, SUM(mrr) AS active_mrr "
        "FROM saas_account_monthly WHERE month = '2026-09' "
        "AND active = 1 GROUP BY segment ORDER BY segment",
    'bank': 'SELECT risk_band, SUM(outstanding) AS exposure '
        'FROM loan_portfolio GROUP BY risk_band ORDER BY risk_band',
    'hospital': 'SELECT unit, ROUND(AVG(avg_wait_minutes), 1) AS avg_wait '
        'FROM hospital_daily_ops GROUP BY unit ORDER BY unit',
    'logistics': 'SELECT route_code, '
        'ROUND(SUM(shipping_cost) / SUM(weight_kg), 2) AS cost_per_kg '
        'FROM logistics_shipments GROUP BY route_code ORDER BY route_code',
  };

  Future<Map<String, String>> build({
    required FlagshipWorkday workday,
    required FlagshipAttempt attempt,
  }) async {
    final sources = tables[workday.companyKey];
    final reference = referenceQueries[workday.companyKey];
    if (sources == null || reference == null) {
      throw StateError('Unsupported reproducible domain.');
    }
    final db = await _database.database;
    final files = <String, String>{};
    final dump = StringBuffer('-- Synthetic DataQuest source only.\n');
    final counts = <String, int>{};

    for (final table in sources) {
      final definitions = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
        [table],
      );
      if (definitions.length != 1 || definitions.first['sql'] == null) {
        throw StateError('Missing synthetic source: $table');
      }
      dump.writeln("${definitions.single['sql']};");
      final rows = await db.query(table);
      counts[table] = rows.length;
      for (final row in rows) {
        final cols = row.keys.toList();
        final names = cols.map((name) => '"$name"').join(', ');
        final values = cols.map((name) => _sqlLiteral(row[name])).join(', ');
        dump.writeln('INSERT INTO "$table" ($names) VALUES ($values);');
      }
      files['data/$table.csv'] = _csv(rows);
    }
    files['dataset.sql'] = dump.toString();
    files['reference_query.sql'] = '$reference;\n';

    final known = await SqlRunner(_database).runReadOnly(reference);
    if (!known.isSuccess || known.truncated) {
      throw StateError('Domain reference query failed for ${workday.companyKey}');
    }
    final audit = SqlResultGrader.grade(
      actualRows: known.rows,
      expectedRows: workday.sqlExpectedRows,
      truncated: known.truncated,
    );
    if (!audit.isCorrect) {
      throw StateError('Reference results mismatch: ${audit.feedback}');
    }
    final submitted = attempt.analysisText.trim();
    final run = attempt.tool == 'SQL' && submitted.isNotEmpty
        ? await SqlRunner(_database).runReadOnly(submitted)
        : null;
    final checked = run != null && run.isSuccess
        ? SqlResultGrader.grade(
            actualRows: run.rows,
            expectedRows: workday.sqlExpectedRows,
            truncated: run.truncated,
          )
        : null;
    files['verification.json'] = const JsonEncoder.withIndent('  ').convert({
      'company': workday.companyKey,
      'dataset_type': 'complete synthetic SQLite snapshot',
      'row_counts': counts,
      'reference_sql_reconciled': true,
      'submitted_sql_executed': run?.isSuccess ?? false,
      'submitted_sql_matches_reference': checked?.isCorrect ?? false,
      'changed_data_robustness_tested': false,
      'external_analyst_replay_completed': false,
      'warning': 'Passing an example dataset does not prove skill transfer. '
          'Non-SQL methods are still simulated.',
    });
    files['REPRODUCE.md'] = '''
# Replay synthetic ${workday.companyName}

Run these commands from the exported project folder in an empty database:

    sqlite3 case.db < dataset.sql
    sqlite3 -header -csv case.db < reference_query.sql

The files inside data/ contain the entire synthetic source tables, not
just preview rows. Inspect verification.json for the actual result status.

This is synthetic training data, not actual company information.
These cases are not yet assessed on changed/unseen data.
''';
    return files;
  }

  static String _sqlLiteral(Object? value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    final escaped = value.toString().replaceAll("'", "''");
    return "'$escaped'";
  }

  static String _csv(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return '';
    final cols = rows.first.keys.toList();
    String encode(Object? value) =>
        '"${(value?.toString() ?? '').replaceAll('"', '""')}"';
    return [
      cols.map(encode).join(','),
      for (final row in rows) cols.map((name) => encode(row[name])).join(','),
    ].join('\n');
  }
}
