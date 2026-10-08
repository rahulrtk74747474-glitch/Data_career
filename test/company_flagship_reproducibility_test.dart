// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:convert';
import 'dart:io';

import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/models/flagship_attempt.dart';
import 'package:dataquest_analyst_career/models/job_ready_v15.dart';
import 'package:dataquest_analyst_career/services/company_flagship_case_service.dart';
import 'package:dataquest_analyst_career/services/flagship_project_export_service.dart';
import 'package:dataquest_analyst_career/services/sql_result_grader.dart';
import 'package:dataquest_analyst_career/services/sql_runner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late AppDatabase database;
  late CompanyFlagshipCaseService cases;
  late List<FlagshipWorkday> workdays;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    temp = await Directory.systemTemp.createTemp('dataquest_company_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: p.join(temp.path, 'test.db'),
    );
    cases = CompanyFlagshipCaseService(database);
    final json = jsonDecode(
      await rootBundle.loadString('assets/content/job_ready_v1_5.json'),
    ) as Map<String, dynamic>;
    workdays = [
      for (final raw in (json['workdays'] as List).skip(1))
        FlagshipWorkday.fromJson(Map<String, dynamic>.from(raw as Map)),
    ];
  });

  tearDown(() async {
    await database.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('all company SQL references run against complete reproducible source',
      () async {
    await cases.ensureReady();
    await cases.ensureReady();
    expect(workdays, hasLength(4));
    for (final workday in workdays) {
      final definition = await cases.definition(workday.companyKey);
      expect((await cases.rows(workday.companyKey)).length,
          greaterThanOrEqualTo(9));
      final actual = await SqlRunner(database).runReadOnly(
        definition['referenceQuery'] as String,
      );
      expect(actual.isSuccess, isTrue, reason: actual.error);
      final grade = SqlResultGrader.grade(
        actualRows: actual.rows,
        expectedRows: workday.sqlExpectedRows,
      );
      expect(grade.isCorrect, isTrue,
          reason: workday.companyKey + ': ' + grade.feedback);
      expect(
        CompanyFlagshipCaseService.integrityWarning(
          definition['referenceQuery'] as String, workday.companyKey,
        ), isNull,
      );
      final holdout = await cases.verifyChangedData(
        workday.companyKey, definition['referenceQuery'] as String,
      );
      expect(holdout.isCorrect, isTrue,
          reason: workday.companyKey + ': ' + holdout.feedback);
      final after = await SqlRunner(database).runReadOnly(
        definition['referenceQuery'] as String,
      );
      expect(after.rows, actual.rows, reason: 'Holdout must roll back');
    }
  });

  test('fixed reported results fail on changed underlying company events',
      () async {
    await cases.ensureReady();
    const hardcoded = '''
SELECT group_name AS plan,
  CASE group_name
    WHEN 'Enterprise' THEN 9500
    WHEN 'Pro' THEN 3800
    ELSE 700
  END AS mrr
FROM dq_case_latest
WHERE case_id = 'saas' AND status = 'active'
GROUP BY group_name
''';
    expect(CompanyFlagshipCaseService.integrityWarning(hardcoded, 'saas'),
        isNull);
    final baseline = await SqlRunner(database).runReadOnly(hardcoded);
    expect(SqlResultGrader.grade(
      actualRows: baseline.rows,
      expectedRows: workdays.first.sqlExpectedRows,
    ).isCorrect, isTrue);
    expect((await cases.verifyChangedData('saas', hardcoded)).isCorrect, isFalse);
  });

  test('company portfolio ZIP contains raw sources and independently checked SQL',
      () async {
    for (final workday in workdays) {
      final definition = await cases.definition(workday.companyKey);
      final attempt = FlagshipAttempt(
        workdayId: workday.id,
        tool: 'SQL',
        analysisText: definition['referenceQuery'] as String,
        managerText: 'This is a synthetic snapshot; compare future months.',
        completedAt: DateTime.utc(2026, 10, 8),
      );
      final exported = await FlagshipProjectExportService(database).export(
        workday: workday, attempt: attempt,
      );
      expect(await File(exported.archivePath).exists(), isTrue);
      final manifest = jsonDecode(
        await File(p.join(exported.directoryPath, 'verification.json'))
            .readAsString(),
      ) as Map<String, dynamic>;
      expect(manifest['baseline_result_matched'], isTrue);
      expect(manifest['changed_data_result_matched'], isTrue);
      expect(manifest['verified_independent_sql'], isTrue);
      expect(await File(p.join(exported.directoryPath, 'data', 'events.csv'))
          .exists(), isTrue);
      expect(await File(p.join(exported.directoryPath, 'REPRODUCE.md'))
          .readAsString(), contains('sqlite3'));
    }
  });
}
