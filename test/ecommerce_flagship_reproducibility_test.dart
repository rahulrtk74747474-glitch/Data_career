import 'dart:convert';
import 'dart:io';

import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/models/flagship_attempt.dart';
import 'package:dataquest_analyst_career/models/job_ready_v15.dart';
import 'package:dataquest_analyst_career/services/ecommerce_flagship_case_service.dart';
import 'package:dataquest_analyst_career/services/flagship_project_export_service.dart';
import 'package:dataquest_analyst_career/services/sql_result_grader.dart';
import 'package:dataquest_analyst_career/services/sql_runner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late AppDatabase database;
  late EcommerceFlagshipCaseService workspace;
  late FlagshipWorkday workday;

  setUp(() async {
    sqfliteFfiInit();
    temp = await Directory.systemTemp.createTemp('dataquest_ec_case_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: p.join(temp.path, 'case_test.db'),
    );
    workspace = EcommerceFlagshipCaseService(database);
    final raw = await rootBundle.loadString(
      'assets/content/job_ready_v1_5.json',
    );
    final pack = jsonDecode(raw) as Map<String, dynamic>;
    workday = FlagshipWorkday.fromJson(
      Map<String, dynamic>.from((pack['workdays'] as List).first as Map),
    );
  });

  tearDown(() async {
    await database.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('case sources seed idempotently and reconcile to true net revenue',
      () async {
    await workspace.ensureReady();
    await workspace.ensureReady();
    final audit = await workspace.audit();
    expect(audit.rawOrderEvents, 16);
    expect(audit.uniqueOrders, 12);
    expect(audit.duplicateOrderEvents, 4);
    expect(audit.rawRefundEvents, 9);
    expect(audit.uniqueRefunds, 7);
    expect(audit.duplicateRefundEvents, 2);
    expect(audit.netRevenue, 16350);

    final run = await SqlRunner(database).runReadOnly(
      EcommerceFlagshipCaseService.referenceQuery,
    );
    expect(run.isSuccess, isTrue, reason: run.error);
    expect(
      SqlResultGrader.grade(
        actualRows: run.rows,
        expectedRows: workday.sqlExpectedRows,
      ).isCorrect,
      isTrue,
    );
  });

  test('summing raw event values instead of trusted cleaned rows fails',
      () async {
    await workspace.ensureReady();
    const incorrectQuery = '''
      SELECT c.segment, SUM(e.gross_amount) AS revenue
      FROM ec_case_order_events e
      JOIN ec_case_customers c ON c.customer_id = e.customer_id
      WHERE e.status = 'completed'
      GROUP BY c.segment
    ''';
    final result = await SqlRunner(database).runReadOnly(incorrectQuery);
    expect(result.isSuccess, isTrue);
    expect(
      SqlResultGrader.grade(
        actualRows: result.rows,
        expectedRows: workday.sqlExpectedRows,
      ).isCorrect,
      isFalse,
    );
    expect(
      EcommerceFlagshipCaseService.queryIntegrityWarning(
        "SELECT 'Consumer' AS segment, 3400 AS revenue",
      ),
      isNotNull,
    );
  });

  test('portfolio exports complete data and verified executable evidence',
      () async {
    final attempt = FlagshipAttempt(
      workdayId: workday.id,
      tool: 'SQL',
      hintsUsed: 2,
      analysisText: EcommerceFlagshipCaseService.referenceQuery,
      managerText: 'Segment net revenue is 3400 / 9550 / 3400.',
      totalScore: 94,
      completedAt: DateTime.utc(2026, 10, 8),
    );
    final exported = await FlagshipProjectExportService(database).export(
      workday: workday,
      attempt: attempt,
    );
    final dir = Directory(exported.directoryPath);
    expect(await dir.exists(), isTrue);
    expect(await File(p.join(dir.path, 'data/order_events.csv'))
        .readAsLines(), hasLength(17));
    expect(await File(p.join(dir.path, 'data/refund_events.csv'))
        .readAsLines(), hasLength(10));
    expect(await File(p.join(dir.path, 'data/customers.csv'))
        .readAsLines(), hasLength(7));
    expect(await File(p.join(dir.path, 'data/clean_orders.csv'))
        .readAsLines(), hasLength(13));
    final verification = jsonDecode(
      await File(p.join(dir.path, 'verification.json')).readAsString(),
    ) as Map<String, dynamic>;
    expect(verification['real_sql_executed'], isTrue);
    expect(verification['hints_used'], 2);
    expect(verification['output_matches_expected'], isTrue);
    expect(verification['net_revenue'], 16350);
    expect(
      await File(p.join(dir.path, 'schema.sql')).readAsString(),
      contains('CREATE VIEW IF NOT EXISTS ec_case_clean_orders'),
    );
    expect(
      await File(p.join(dir.path, 'REPRODUCE.md')).readAsString(),
      contains('sqlite3 case.db'),
    );
  });

  test('historic or non-SQL attempt exports are not mislabeled verified',
      () async {
    final attempt = FlagshipAttempt(
      workdayId: workday.id,
      tool: 'Pandas',
      analysisText: "df.groupby('segment').sum()",
      completedAt: DateTime.utc(2026, 10, 8),
    );
    final export = await FlagshipProjectExportService(database).export(
      workday: workday,
      attempt: attempt,
    );
    final verification = jsonDecode(
      await File(p.join(export.directoryPath, 'verification.json'))
          .readAsString(),
    ) as Map<String, dynamic>;
    expect(verification['real_sql_executed'], isFalse);
    expect(verification['output_matches_expected'], isFalse);
  });
}
