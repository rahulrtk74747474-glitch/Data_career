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

  tearDown(() async {
    await appDatabase.close();
  });

  test('real SQLite query executes against seeded campaign data', () async {
    final result = await SqlRunner(appDatabase).runReadOnly(
      '''
      SELECT channel, SUM(conversions) AS total_conversions
      FROM campaign_performance
      GROUP BY channel
      ''',
    );

    expect(result.isSuccess, isTrue);
    expect(result.rows, hasLength(2));

    final grade = SqlResultGrader.grade(
      actualRows: result.rows,
      expectedRows: const [
        {'channel': 'Search', 'total_conversions': 163},
        {'channel': 'Social', 'total_conversions': 93},
      ],
    );

    expect(grade.isCorrect, isTrue);
  });

  test('SQL runner blocks mutating statements', () async {
    final result = await SqlRunner(appDatabase).runReadOnly(
      'DELETE FROM campaign_performance',
    );
    expect(result.isSuccess, isFalse);
  });
}
