import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('career campaign has 12 ordered projects with valid task references',
      () async {
    final missionPack =
        await _asset('assets/content/career_missions_v1.json');
    final missions = missionPack['missions'] as List<dynamic>;
    expect(missions, hasLength(12));

    final taskIds = <String>{};
    for (final asset in const [
      'assets/content/phase1_tasks.json',
      'assets/content/phase2_tasks.json',
      'assets/content/phase3_tasks.json',
      'assets/content/phase4_tasks.json',
      'assets/content/saas_retention_v1.json',
      'assets/content/saas_sql_v1.json',
      'assets/content/saas_statistics_v1.json',
      'assets/content/saas_nrr_v1.json',
      'assets/content/bank_tasks_v1.json',
      'assets/content/hospital_tasks_v1.json',
      'assets/content/logistics_tasks_v1.json',
      'assets/content/business_metrics_v1.json',
    ]) {
      final pack = await _asset(asset);
      for (final raw in pack['tasks'] as List<dynamic>) {
        taskIds.add((raw as Map)['id'] as String);
      }
    }

    final orders = <int>[];
    final companies = <String>{};
    for (final raw in missions) {
      final mission = Map<String, dynamic>.from(raw as Map);
      orders.add((mission['order'] as num).toInt());
      companies.add(mission['companyKey'] as String);
      expect((mission['briefing'] as String).trim(), isNotEmpty);
      expect((mission['resumeBullet'] as String).trim(), isNotEmpty);
      expect((mission['managerFeedback'] as String).trim(), isNotEmpty);
      final ids = List<String>.from(mission['taskIds'] as List<dynamic>);
      expect(ids.length, greaterThanOrEqualTo(2));
      for (final id in ids) {
        expect(taskIds, contains(id), reason: '${mission['id']} -> $id');
      }
    }

    expect(orders, List<int>.generate(12, (index) => index + 1));
    expect(
      companies,
      {'ecommerce', 'saas', 'bank', 'hospital', 'logistics'},
    );
  });

  test('BI lab contains eight Power BI application challenges', () async {
    final pack =
        await _asset('assets/content/dashboard_challenges_v1.json');
    final challenges = pack['challenges'] as List<dynamic>;
    final powerBi = challenges
        .where((raw) => (raw as Map)['skillKey'] == 'powerbi')
        .toList();

    expect(challenges, hasLength(13));
    expect(powerBi, hasLength(8));
    for (final raw in powerBi) {
      final item = raw as Map;
      expect(item['companyKey'], isNotNull);
      expect(item['xp'], greaterThanOrEqualTo(100));
      expect(item['hints'] as List<dynamic>, hasLength(3));
    }
  });

  test('foundation academy includes a complete Power BI path', () async {
    final pack =
        await _asset('assets/content/foundation_academy_v1.json');
    final lessons = pack['lessons'] as List<dynamic>;
    final powerBi = lessons
        .where((raw) => (raw as Map)['trackKey'] == 'powerbi')
        .toList();

    expect(pack['trackCount'], 8);
    expect(powerBi, hasLength(8));
    expect(
      powerBi.map((raw) => (raw as Map)['skillKey']).toSet(),
      {'powerbi'},
    );
    expect(
      powerBi.map((raw) => (raw as Map)['order']).toList(),
      List<int>.generate(8, (index) => index + 1),
    );
  });
}

Future<Map<String, dynamic>> _asset(String path) async {
  final raw = await rootBundle.loadString(path);
  return jsonDecode(raw) as Map<String, dynamic>;
}
