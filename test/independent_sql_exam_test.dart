import 'dart:io';

import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/services/independent_sql_exam_service.dart';
import 'package:dataquest_analyst_career/services/sql_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late Directory temp;
  late IndependentSqlExamService exam;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    temp = await Directory.systemTemp.createTemp('dq_independent_');
    database = AppDatabase(factory: databaseFactoryFfi,
        overridePath: p.join(temp.path, 'test.db'));
    exam = IndependentSqlExamService(database);
  });
  tearDown(() async {
    await database.close();
    await temp.delete(recursive: true);
  });

  test('independent exam passes a data-derived answer and saves credit', () async {
    expect(await exam.hasPassed(), isFalse);
    // The exam owns its own source and creates it before SQL runs.
    await exam.ensureReady();
    final result = await exam.assess(IndependentSqlExamService.referenceQuery);
    expect(result.correct, isTrue, reason: result.feedback);
    expect(result.verifiedOnChangedData, isTrue);
    expect(await exam.hasPassed(), isTrue);
    final after = await SqlRunner(database).runReadOnly(
      IndependentSqlExamService.referenceQuery,
    );
    expect(after.rows, isNotEmpty);
    final repeated = await exam.assess(IndependentSqlExamService.referenceQuery);
    expect(repeated.attempts, 2);
    expect(repeated.correct, isTrue);
  });

  test('fixed hardcoded totals never earn independent pass', () async {
    await exam.ensureReady();
    const answer = '''
SELECT region,
CASE region
  WHEN 'North' THEN 2000
  WHEN 'South' THEN 2350
  ELSE 2200
END AS revenue
FROM dq_exam_latest
GROUP BY region
''';
    final result = await exam.assess(answer);
    expect(result.correct, isFalse);
    expect(await exam.hasPassed(), isFalse);
  });

  test('exam rejects source-only queries and unsafe SQL', () async {
    await exam.ensureReady();
    final raw = await exam.assess(
      'SELECT region, SUM(gross_amount) AS revenue '
      'FROM dq_exam_event GROUP BY region',
    );
    expect(raw.correct, isFalse);
    final destructive = await exam.assess(
      'DELETE FROM dq_exam_latest',
    );
    expect(destructive.correct, isFalse);
    expect(await exam.hasPassed(), isFalse);
  });
}
