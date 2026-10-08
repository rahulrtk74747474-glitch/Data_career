import 'dart:io';

import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/services/company_followup_service.dart';
import 'package:dataquest_analyst_career/services/sql_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late AppDatabase database;
  setUp(() async {
    sqfliteFfiInit();
    temp = await Directory.systemTemp.createTemp('dq_followup_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: p.join(temp.path, 'test.db'),
    );
  });
  tearDown(() async {
    await database.close();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('record persists four daily rows, includes external shock and costs',
      () async {
    final service = CompanyFollowupService(database);
    final first = await service.record(
      workdayId: 'hospital-case',
      company: 'hospital',
      score: 93,
      hintsUsed: 0,
      managerRecommendation: 'Pilot a small staffing experiment first.',
    );
    expect(first, hasLength(4));
    expect(first[0].day, 0);
    expect(first[0].metricValue, 59);
    expect(first[3].metricValue, lessThan(first[0].metricValue));
    expect(first[2].managerMessage, contains('staff absence'));
    expect(first[3].extraCost, greaterThan(first[0].extraCost));
    expect(first[0].approach, 'controlled_pilot');

    final duplicate = await service.record(
      workdayId: 'hospital-case',
      company: 'hospital',
      score: 10,
      hintsUsed: 3,
      managerRecommendation: 'Rollout to all units instead.',
    );
    expect(duplicate[3].metricValue, first[3].metricValue);
    expect(duplicate[0].approach, 'controlled_pilot');

    final sql = await SqlRunner(database).runReadOnly(
      "SELECT day_number, metric_value FROM dq_company_followup_daily "
      "WHERE workday_id='hospital-case' ORDER BY day_number",
    );
    expect(sql.isSuccess, isTrue);
    expect(sql.rows.length, 4);
  });

  test('different decisions create different effects with bounded metrics',
      () async {
    final service = CompanyFollowupService(database);
    final cautious = await service.record(
      workdayId: 'ecommerce-watch',
      company: 'ecommerce',
      score: 90,
      hintsUsed: 0,
      managerRecommendation: 'Monitor the refund rate and investigate first.',
    );
    final rollout = await service.record(
      workdayId: 'ecommerce-launch',
      company: 'ecommerce',
      score: 90,
      hintsUsed: 0,
      managerRecommendation: 'Launch and expand the changes broadly.',
    );
    expect(rollout[3].metricValue, lessThan(cautious[3].metricValue));
    expect(rollout[3].extraCost, greaterThan(cautious[3].extraCost));
    for (final day in rollout) {
      expect(day.metricValue, inInclusiveRange(0, 100));
      expect(day.risk, inInclusiveRange(0, 100));
    }
  });

  test('explicit career reset clears all persisted company outcomes', () async {
    final service = CompanyFollowupService(database);
    await service.record(
      workdayId: 'case-to-reset',
      company: 'saas',
      score: 95,
      hintsUsed: 0,
      managerRecommendation: 'Pilot before expanding.',
    );
    expect(await service.load('case-to-reset'), hasLength(4));
    await service.resetAll();
    expect(await service.load('case-to-reset'), isEmpty);
  });

}
