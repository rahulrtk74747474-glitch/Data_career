import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v1.5 contains five complete flagship workdays and job-ready systems',
      () async {
    final raw =
        await rootBundle.loadString('assets/content/job_ready_v1_5.json');
    final pack = jsonDecode(raw) as Map<String, dynamic>;

    final workdays = pack['workdays'] as List<dynamic>;
    final playbooks = pack['domainPlaybooks'] as List<dynamic>;
    final leadership = pack['leadershipCases'] as List<dynamic>;
    final coaches = pack['coachScenarios'] as List<dynamic>;

    expect(workdays, hasLength(5));
    expect(playbooks, hasLength(5));
    expect(leadership, hasLength(9));
    expect(coaches, hasLength(6));

    final companies = <String>{};
    for (final rawItem in workdays) {
      final item = Map<String, dynamic>.from(rawItem as Map);
      companies.add(item['companyKey'] as String);
      expect(item['correctIssues'] as List<dynamic>, hasLength(3));
      expect(
        Map<String, dynamic>.from(item['toolScores'] as Map).keys.toSet(),
        {'SQL', 'Pandas', 'Power BI', 'Excel'},
      );
      expect((item['sqlExpectedRows'] as List<dynamic>), isNotEmpty);
      expect((item['managerReference'] as String).trim(), isNotEmpty);
      expect((item['resumeBullet'] as String).trim(), isNotEmpty);
      expect((item['bonusXp'] as num).toInt(), greaterThanOrEqualTo(200));
    }

    expect(
      companies,
      {'ecommerce', 'saas', 'bank', 'hospital', 'logistics'},
    );
  });

  test('all business playbooks have usable metric definitions', () async {
    final raw =
        await rootBundle.loadString('assets/content/job_ready_v1_5.json');
    final pack = jsonDecode(raw) as Map<String, dynamic>;
    for (final rawBook in pack['domainPlaybooks'] as List<dynamic>) {
      final book = Map<String, dynamic>.from(rawBook as Map);
      expect((book['levers'] as List<dynamic>).length, greaterThanOrEqualTo(5));
      final metrics = book['metrics'] as List<dynamic>;
      expect(metrics.length, greaterThanOrEqualTo(6));
      for (final rawMetric in metrics) {
        final metric = Map<String, dynamic>.from(rawMetric as Map);
        expect((metric['formula'] as String).trim(), isNotEmpty);
        expect((metric['use'] as String).trim(), isNotEmpty);
        expect((metric['trap'] as String).trim(), isNotEmpty);
      }
    }
  });
}
