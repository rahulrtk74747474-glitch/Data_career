import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/services/sql_result_grader.dart';
import 'package:dataquest_analyst_career/services/sql_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late SqlRunner runner;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
    runner = SqlRunner(database);
  });

  tearDown(() => database.close());

  test('bank loan exposure aggregates by risk band', () async {
    final result = await runner.runReadOnly(
      'SELECT risk_band, SUM(outstanding) AS total_outstanding '
      'FROM loan_portfolio GROUP BY risk_band',
    );

    expect(result.isSuccess, isTrue);

    final grade = SqlResultGrader.grade(
      actualRows: result.rows,
      expectedRows: const [
        {'risk_band': 'High', 'total_outstanding': 500000},
        {'risk_band': 'Low', 'total_outstanding': 2420000},
        {'risk_band': 'Medium', 'total_outstanding': 45000},
      ],
    );

    expect(grade.isCorrect, isTrue);
  });

  test('transaction review workload is seeded without outcome labels', () async {
    final result = await runner.runReadOnly(
      'SELECT channel, COUNT(*) AS flagged_transactions '
      'FROM bank_transactions WHERE review_flag = 1 GROUP BY channel',
    );

    expect(result.isSuccess, isTrue);
    expect(
      SqlResultGrader.grade(
        actualRows: result.rows,
        expectedRows: const [
          {'channel': 'atm', 'flagged_transactions': 1},
          {'channel': 'online', 'flagged_transactions': 2},
        ],
      ).isCorrect,
      isTrue,
    );
  });
}
