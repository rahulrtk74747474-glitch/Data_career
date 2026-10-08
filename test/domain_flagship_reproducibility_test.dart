import 'dart:convert';
import 'dart:io';

import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/models/flagship_attempt.dart';
import 'package:dataquest_analyst_career/models/job_ready_v15.dart';
import 'package:dataquest_analyst_career/services/domain_flagship_export_bundle.dart';
import 'package:dataquest_analyst_career/services/flagship_project_export_service.dart';
import 'package:dataquest_analyst_career/services/sql_result_grader.dart';
import 'package:dataquest_analyst_career/services/sql_runner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late Directory temp;
  setUp(() async {
    sqfliteFfiInit();
    temp = await Directory.systemTemp.createTemp('dq_domain_replay_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: p.join(temp.path, 'game.db'),
    );
  });
  tearDown(() async {
    await database.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('four synthetic company queries reproduce their workday references',
      () async {
    final raw = await rootBundle.loadString('assets/content/job_ready_v1_5.json');
    final pack = jsonDecode(raw) as Map<String, dynamic>;
    for (final item in (pack['workdays'] as List<dynamic>).skip(1)) {
      final w = FlagshipWorkday.fromJson(Map<String, dynamic>.from(item as Map));
      final query = DomainFlagshipExportBundle.referenceQueries[w.companyKey]!;
      final run = await SqlRunner(database).runReadOnly(query);
      expect(run.isSuccess, isTrue, reason: w.companyKey);
      expect(SqlResultGrader.grade(
        actualRows: run.rows,
        expectedRows: w.sqlExpectedRows,
        truncated: run.truncated,
      ).isCorrect, isTrue, reason: w.companyKey);
    }
  });

  test('four flagship portfolios contain full source data and replay SQL',
      () async {
    final raw = await rootBundle.loadString('assets/content/job_ready_v1_5.json');
    final pack = jsonDecode(raw) as Map<String, dynamic>;
    for (final item in (pack['workdays'] as List<dynamic>).skip(1)) {
      final w = FlagshipWorkday.fromJson(Map<String, dynamic>.from(item as Map));
      final query = DomainFlagshipExportBundle.referenceQueries[w.companyKey]!;
      final attempt = FlagshipAttempt(
        workdayId: w.id,
        tool: 'SQL',
        analysisText: query,
      );
      final exported = await FlagshipProjectExportService(database)
          .export(workday: w, attempt: attempt);
      expect(await File(exported.archivePath).exists(), isTrue);
      final sql = await File(p.join(exported.directoryPath, 'dataset.sql'))
          .readAsString();
      for (final name in DomainFlagshipExportBundle.tables[w.companyKey]!) {
        expect(sql, contains('CREATE TABLE'));
        expect(sql, contains(name));
        final csv = File(p.join(exported.directoryPath, 'data/$name.csv'));
        expect(await csv.exists(), isTrue);
        expect(await csv.length(), greaterThan(0));
      }
      final verification = jsonDecode(await File(
        p.join(exported.directoryPath, 'verification.json'),
      ).readAsString()) as Map<String, dynamic>;
      expect(verification['reference_sql_reconciled'], isTrue);
      expect(verification['submitted_sql_matches_reference'], isTrue);
      expect(verification['changed_data_robustness_tested'], isFalse);
      expect(verification['external_analyst_replay_completed'], isFalse);
    }
  });
}
