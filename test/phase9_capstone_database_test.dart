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

  test('cross-company service changes are reproducible offline', () async {
    final result = await runner.runReadOnly(
      "SELECT company_key, "
      "ROUND(MAX(CASE WHEN period = 'Current' THEN service_score END) - "
      "MAX(CASE WHEN period = 'Baseline' THEN service_score END), 1) "
      "AS service_change "
      "FROM capstone_company_kpis GROUP BY company_key",
    );

    expect(result.isSuccess, isTrue);
    expect(
      SqlResultGrader.grade(
        actualRows: result.rows,
        expectedRows: const [
          {'company_key': 'bank', 'service_change': 2.0},
          {'company_key': 'ecommerce', 'service_change': 4.0},
          {'company_key': 'hospital', 'service_change': 5.0},
          {'company_key': 'logistics', 'service_change': 6.0},
          {'company_key': 'saas', 'service_change': 3.0},
        ],
      ).isCorrect,
      isTrue,
    );
  });

  test('current portfolio service average is 87.6', () async {
    final result = await runner.runReadOnly(
      "SELECT ROUND(AVG(service_score), 1) AS avg_service "
      "FROM capstone_company_kpis WHERE period = 'Current'",
    );

    expect(result.isSuccess, isTrue);
    expect(result.rows.single['avg_service'], 87.6);
  });
}
