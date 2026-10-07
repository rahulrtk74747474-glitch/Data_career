import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('core SQL curriculum has exactly 20 progressive tasks', () async {
    final pack = await _asset('assets/content/sql_lab_core_v2.json');
    final tasks = pack['tasks'] as List<dynamic>;

    expect(tasks, hasLength(20));
    expect(
      tasks.map((item) => (item as Map)['difficulty']).toSet(),
      containsAll({'Beginner', 'Intermediate', 'Advanced'}),
    );
    expect(
      tasks.any(
        (item) => (item as Map)['title']
            .toString()
            .toLowerCase()
            .contains('moving average'),
      ),
      isTrue,
    );
  });

  test('generated Advanced SQL pack has 25 tasks and five industries', () async {
    final pack =
        await _asset('assets/content/generated_sql_advanced_25_v1.json');
    final tasks = pack['tasks'] as List<dynamic>;

    expect(tasks, hasLength(25));
    expect(pack['generatedFor'], {
      'skill': 'SQL',
      'level': 'Advanced',
    });
    expect(
      tasks.map((item) => (item as Map)['companyKey']).toSet(),
      {'ecommerce', 'saas', 'bank', 'hospital', 'logistics'},
    );
    for (final item in tasks) {
      final task = Map<String, dynamic>.from(item as Map);
      expect(task['difficulty'], 'Advanced');
      expect((task['hints'] as List<dynamic>), hasLength(3));
      expect(task['expectedRows'], isNotEmpty);
      expect(task['rubric'], {
        'resultAccuracy': 70,
        'correctGrainAndFilters': 20,
        'readableQueryStructure': 10,
      });
    }
  });

  test('spreadsheet/cleaning and analytics packs each contain 15 tasks', () async {
    final spreadsheet =
        await _asset('assets/content/spreadsheet_cleaning_v1.json');
    final analytics =
        await _asset('assets/content/analytics_studio_v1.json');

    final spreadsheetTasks =
        spreadsheet['challenges'] as List<dynamic>;
    final analyticsTasks = analytics['challenges'] as List<dynamic>;

    expect(spreadsheetTasks, hasLength(15));
    expect(
      spreadsheetTasks
          .where((item) => (item as Map)['skillKey'] == 'spreadsheets')
          .length,
      10,
    );
    expect(
      spreadsheetTasks
          .where((item) => (item as Map)['skillKey'] == 'cleaning')
          .length,
      5,
    );
    expect(analyticsTasks, hasLength(15));
    expect(
      analyticsTasks
          .where((item) => (item as Map)['mode'] == 'statistics')
          .length,
      8,
    );
    expect(
      analyticsTasks
          .where((item) => (item as Map)['mode'] == 'dashboard')
          .length,
      7,
    );
  });

  test('Pandas curriculum reaches 15 guided tasks plus business metrics', () async {
    final core = await _asset('assets/content/pandas_challenges_v1.json');
    final expansion =
        await _asset('assets/content/pandas_expansion_v1.json');
    final business =
        await _asset('assets/content/business_metrics_v1.json');

    final pandasTasks = <dynamic>[
      ...(core['challenges'] as List<dynamic>),
      ...(expansion['challenges'] as List<dynamic>),
    ];
    expect(pandasTasks, hasLength(15));
    expect(business['tasks'] as List<dynamic>, hasLength(7));
    for (final item in pandasTasks) {
      expect((item as Map)['hints'] as List<dynamic>, hasLength(3));
    }
  });

  test('narrative pack includes requested events and insight coaching', () async {
    final narrative = await _asset('assets/content/narrative_v1.json');

    expect(narrative['insightScenarios'] as List<dynamic>, hasLength(10));
    expect(narrative['events'] as List<dynamic>, hasLength(4));
    final titles = (narrative['events'] as List<dynamic>)
        .map((item) => (item as Map)['title'])
        .toSet();
    expect(
      titles,
      containsAll({
        'Dirty Vendor Data',
        'Urgent CEO Request',
        'Conflicting Reports',
        'Privacy Incident',
      }),
    );
  });
}

Future<Map<String, dynamic>> _asset(String path) async {
  final raw = await rootBundle.loadString(path);
  return jsonDecode(raw) as Map<String, dynamic>;
}
