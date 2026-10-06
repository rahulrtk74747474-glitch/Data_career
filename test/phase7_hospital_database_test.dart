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

  test('hospital wait time aggregates by unit', () async {
    final result = await runner.runReadOnly(
      'SELECT unit, ROUND(AVG(avg_wait_minutes), 1) AS avg_wait_minutes '
      'FROM hospital_daily_ops GROUP BY unit',
    );

    expect(result.isSuccess, isTrue);
    expect(
      SqlResultGrader.grade(
        actualRows: result.rows,
        expectedRows: const [
          {'unit': 'Emergency', 'avg_wait_minutes': 59.0},
          {'unit': 'Outpatient', 'avg_wait_minutes': 30.0},
        ],
      ).isCorrect,
      isTrue,
    );
  });

  test('capacity forecast exposes positive operational gaps', () async {
    final result = await runner.runReadOnly(
      'SELECT day_name, expected_arrivals - planned_capacity AS capacity_gap '
      'FROM hospital_capacity_forecast '
      'WHERE expected_arrivals > planned_capacity',
    );

    expect(result.isSuccess, isTrue);
    expect(
      SqlResultGrader.grade(
        actualRows: result.rows,
        expectedRows: const [
          {'day_name': 'Thursday', 'capacity_gap': 5},
          {'day_name': 'Friday', 'capacity_gap': 15},
          {'day_name': 'Saturday', 'capacity_gap': 25},
          {'day_name': 'Sunday', 'capacity_gap': 5},
        ],
      ).isCorrect,
      isTrue,
    );
  });
}
