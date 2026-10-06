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

  test('route SLA aggregation returns total and on-time counts', () async {
    final result = await runner.runReadOnly(
      'SELECT route_code, COUNT(*) AS shipment_count, '
      'SUM(CASE WHEN actual_hours <= promised_hours THEN 1 ELSE 0 END) '
      'AS on_time_shipments '
      'FROM logistics_shipments GROUP BY route_code',
    );

    expect(result.isSuccess, isTrue);
    expect(
      SqlResultGrader.grade(
        actualRows: result.rows,
        expectedRows: const [
          {
            'route_code': 'NS-1',
            'shipment_count': 2,
            'on_time_shipments': 0,
          },
          {
            'route_code': 'NW-1',
            'shipment_count': 3,
            'on_time_shipments': 2,
          },
          {
            'route_code': 'SN-1',
            'shipment_count': 2,
            'on_time_shipments': 1,
          },
          {
            'route_code': 'WE-1',
            'shipment_count': 3,
            'on_time_shipments': 1,
          },
        ],
      ).isCorrect,
      isTrue,
    );
  });

  test('throughput forecast exposes positive capacity gaps', () async {
    final result = await runner.runReadOnly(
      'SELECT day_name, expected_shipments - planned_throughput '
      'AS capacity_gap FROM logistics_throughput_forecast '
      'WHERE expected_shipments > planned_throughput',
    );

    expect(result.isSuccess, isTrue);
    expect(
      SqlResultGrader.grade(
        actualRows: result.rows,
        expectedRows: const [
          {'day_name': 'Thursday', 'capacity_gap': 10},
          {'day_name': 'Friday', 'capacity_gap': 40},
          {'day_name': 'Saturday', 'capacity_gap': 70},
          {'day_name': 'Sunday', 'capacity_gap': 20},
        ],
      ).isCorrect,
      isTrue,
    );
  });

  test('warehouse peak utilization is reproducible offline', () async {
    final result = await runner.runReadOnly(
      'SELECT warehouse, '
      'ROUND(MAX(100.0 * ending_units / capacity_units), 1) '
      'AS peak_utilization_pct '
      'FROM logistics_inventory_flow GROUP BY warehouse',
    );

    expect(result.isSuccess, isTrue);
    expect(
      SqlResultGrader.grade(
        actualRows: result.rows,
        expectedRows: const [
          {'warehouse': 'WH-North', 'peak_utilization_pct': 95.0},
          {'warehouse': 'WH-West', 'peak_utilization_pct': 97.8},
        ],
      ).isCorrect,
      isTrue,
    );
  });
}
