import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/services/sql_result_grader.dart';
import 'package:dataquest_analyst_career/services/sql_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase appDatabase;
  setUp(() {
    sqfliteFfiInit();
    appDatabase = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
  });
  tearDown(() => appDatabase.close());

  test('real SQLite query executes and grades', () async {
    final result = await SqlRunner(appDatabase).runReadOnly(
      'SELECT channel, SUM(conversions) AS total_conversions '
      'FROM campaign_performance GROUP BY channel',
    );
    expect(result.isSuccess, isTrue);
    expect(
      SqlResultGrader.grade(
        actualRows: result.rows,
        expectedRows: const [
          {'channel': 'Search', 'total_conversions': 163},
          {'channel': 'Social', 'total_conversions': 93},
        ],
      ).isCorrect,
      isTrue,
    );
  });

  test('runner blocks mutations and multiple statements', () async {
    final mutation =
        await SqlRunner(appDatabase).runReadOnly('DELETE FROM orders');
    final multiple =
        await SqlRunner(appDatabase).runReadOnly('SELECT 1; SELECT 2;');
    expect(mutation.isSuccess, isFalse);
    expect(multiple.isSuccess, isFalse);
    expect(mutation.error, contains('read-only'));
  });

  test('runner explains missing table and column plainly', () async {
    final table =
        await SqlRunner(appDatabase).runReadOnly('SELECT * FROM missing_table');
    final column = await SqlRunner(appDatabase)
        .runReadOnly('SELECT missing_column FROM orders');
    expect(table.error, contains('table name does not exist'));
    expect(column.error, contains('column names'));
  });

  test('grader preserves column-to-value relationships', () {
    final grade = SqlResultGrader.grade(
      actualRows: const [{'customer': 'A', 'revenue': 100}],
      expectedRows: const [{'customer': '100', 'revenue': 'A'}],
    );
    expect(grade.isCorrect, isFalse);
  });

  test('grader identifies alias mismatch', () {
    final grade = SqlResultGrader.grade(
      actualRows: const [{'segment': 'SMB', 'sum(revenue)': 100}],
      expectedRows: const [{'segment': 'SMB', 'revenue': 100}],
    );
    expect(grade.isCorrect, isFalse);
    expect(grade.feedback, contains('output columns'));
    expect(grade.feedback, contains('revenue'));
  });

  test('SQL grading rejects a 100-row truncated result', () async {
    final run = await SqlRunner(appDatabase).runReadOnly(
      'WITH RECURSIVE seq(x) AS '
      '(SELECT 1 UNION ALL SELECT x + 1 FROM seq WHERE x < 120) '
      'SELECT x FROM seq',
    );
    expect(run.isSuccess, isTrue);
    expect(run.rows.length, 100);
    expect(run.truncated, isTrue);
    final grade = SqlResultGrader.grade(
      actualRows: run.rows,
      expectedRows: [
        for (var i = 1; i <= 100; i++) {'x': i},
      ],
      truncated: run.truncated,
    );
    expect(grade.isCorrect, isFalse);
    expect(grade.feedback, contains('preview limit'));
  });

}
