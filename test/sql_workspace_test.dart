import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/repositories/sql_workspace_repository.dart';
import 'package:dataquest_analyst_career/services/sql_result_grader.dart';
import 'package:dataquest_analyst_career/services/sql_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
  });

  tearDown(() => database.close());

  test('schema browser exposes career learning tables', () async {
    final schemas = await SqlWorkspaceRepository(database).loadSchemas();
    final names = schemas.map((schema) => schema.name).toSet();

    expect(
      names,
      containsAll({
        'customers',
        'orders',
        'loan_portfolio',
        'bank_transactions',
        'hospital_daily_ops',
        'hospital_capacity_forecast',
      }),
    );
  });

  test('join ticket returns expected completed revenue by segment', () async {
    final result = await SqlRunner(database).runReadOnly('''
      SELECT c.segment, SUM(o.revenue) AS total_revenue
      FROM customers c
      JOIN orders o ON c.customer_id = o.customer_id
      WHERE o.status = 'completed'
      GROUP BY c.segment
    ''');

    expect(result.isSuccess, isTrue);
    final grade = SqlResultGrader.grade(
      actualRows: result.rows,
      expectedRows: const [
        {'segment': 'Consumer', 'total_revenue': 3100},
        {'segment': 'Enterprise', 'total_revenue': 8000},
        {'segment': 'SMB', 'total_revenue': 2300},
      ],
    );
    expect(grade.isCorrect, isTrue);
  });

  test('filter aggregation ticket returns expected status metrics', () async {
    final result = await SqlRunner(database).runReadOnly('''
      SELECT status, COUNT(*) AS order_count, SUM(revenue) AS total_revenue
      FROM orders
      WHERE revenue >= 1000
      GROUP BY status
    ''');

    final grade = SqlResultGrader.grade(
      actualRows: result.rows,
      expectedRows: const [
        {'status': 'completed', 'order_count': 6, 'total_revenue': 12600},
        {'status': 'refunded', 'order_count': 1, 'total_revenue': 1400},
      ],
    );
    expect(grade.isCorrect, isTrue);
  });
}
