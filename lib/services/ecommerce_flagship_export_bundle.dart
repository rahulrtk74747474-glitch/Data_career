import 'dart:convert';

import '../data/app_database.dart';
import '../models/flagship_attempt.dart';
import '../models/job_ready_v15.dart';
import 'ecommerce_flagship_case_service.dart';
import 'sql_result_grader.dart';
import 'sql_runner.dart';

/// Generates files from the same SQLite rows the learner actually queried.
class EcommerceFlagshipExportBundle {
  const EcommerceFlagshipExportBundle(this._database);
  final AppDatabase _database;

  Future<Map<String, String>> build({
    required FlagshipWorkday workday,
    required FlagshipAttempt attempt,
  }) async {
    final workspace = EcommerceFlagshipCaseService(_database);
    final tables = await workspace.exportTables();
    final audit = await workspace.audit();
    final files = <String, String>{};
    for (final entry in tables.entries) {
      files['data/${entry.key}.csv'] = _csv(entry.value);
    }

    final candidate = attempt.analysisText.trim();
    final credibleSql = attempt.tool == 'SQL' &&
        EcommerceFlagshipCaseService.queryIntegrityWarning(candidate) == null;
    final execution = credibleSql
        ? await SqlRunner(_database).runReadOnly(candidate)
        : null;
    final grade = execution != null && execution.isSuccess
        ? SqlResultGrader.grade(
            actualRows: execution.rows,
            expectedRows: workday.sqlExpectedRows,
          )
        : null;
    final verified = grade?.isCorrect ?? false;

    final report = <String, Object?>{
      'dataset': 'Synthetic e-commerce case',
      'dataset_version': EcommerceFlagshipCaseService.datasetVersion,
      'executed_tool': attempt.tool,
      'real_sql_executed': execution?.isSuccess ?? false,
      'references_case_tables': credibleSql,
      'output_matches_expected': verified,
      'row_count': execution?.rows.length ?? 0,
      'net_revenue': audit.netRevenue,
      'raw_order_events': audit.rawOrderEvents,
      'unique_orders': audit.uniqueOrders,
      'raw_refund_events': audit.rawRefundEvents,
      'unique_refunds': audit.uniqueRefunds,
      'note': verified
          ? 'Verified only on this full synthetic dataset; not proof of generalization.'
          : 'This attempt is not independently verified on the version 2 case dataset.',
    };

    files.addAll({
      'schema.sql': EcommerceFlagshipCaseService.portableSchema,
      'reference_query.sql':
          '${EcommerceFlagshipCaseService.referenceQuery};\n',
      'quality_checks.sql': '''
SELECT COUNT(*) AS order_events, COUNT(DISTINCT order_id) AS unique_orders
FROM ec_case_order_events;
SELECT COUNT(*) AS refund_events, COUNT(DISTINCT refund_id) AS unique_refunds
FROM ec_case_refund_events;
SELECT SUM(net_revenue) AS recognized_revenue
FROM ec_case_clean_orders;
''',
      'verification.json':
          '${const JsonEncoder.withIndent('  ').convert(report)}\n',
      'verified_result.csv': execution?.isSuccess == true
          ? _csv(execution!.rows)
          : '',
      'REPRODUCE.md': _reproduce(verified, attempt.tool == 'SQL'),
    });
    return files;
  }

  static String _reproduce(bool verified, bool sqlAttempt) => '''
# Reproduce the synthetic e-commerce case

Submitted SQL verification: ${verified ? 'PASS on this dataset' : 'NOT VERIFIED'}.
This folder contains **all** 6 customers, 16 order events and 9 refund
events, not a subset. Duplicate raw ingestions are intentional.

With SQLite CLI version 3.32 or newer, run from the portfolio folder:

    sqlite3 case.db < schema.sql
    sqlite3 case.db ".mode csv" ".import --skip 1 data/customers.csv ec_case_customers"
    sqlite3 case.db ".mode csv" ".import --skip 1 data/order_events.csv ec_case_order_events"
    sqlite3 case.db ".mode csv" ".import --skip 1 data/refund_events.csv ec_case_refund_events"
    sqlite3 -header -csv case.db < ${sqlAttempt ? 'analysis.sql' : 'reference_query.sql'} > replay_result.csv
    sqlite3 -header -csv case.db < quality_checks.sql

If your previous analysis did not produce the expected output, execute
reference_query.sql instead to compare. The schema defines a SQLite view
named ec_case_clean_orders using latest events per order_id and refund_id.

Net recognized revenue includes only completed orders, less unique partial
refunds. Fully refunded and cancelled orders count as zero. Expected total:
16350 (Consumer 3400, SMB 3400, Enterprise 9550).

The data is synthetic and represents one snapshot. It cannot independently
establish historical growth, profitability or causal commercial impact.
See verification.json for actual execution outcome and limitations.
''';

  static String _csv(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return '';
    final columns = rows.first.keys.toList();
    final lines = <String>[columns.map(_escape).join(',')];
    for (final row in rows) {
      lines.add(
        columns.map((key) => _escape(row[key]?.toString() ?? '')).join(','),
      );
    }
    return lines.join('\n');
  }

  static String _escape(String value) =>
      '"${value.replaceAll('"', '""')}"';
}
