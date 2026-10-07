import 'dart:convert';

import 'package:dataquest_analyst_career/models/analyst_task.dart';
import 'package:dataquest_analyst_career/models/analytics_challenge.dart';
import 'package:dataquest_analyst_career/models/dashboard_challenge.dart';
import 'package:dataquest_analyst_career/models/pandas_challenge.dart';
import 'package:dataquest_analyst_career/models/spreadsheet_challenge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('major learning labs expose full solutions', () async {
    final sql = await _asset('assets/content/sql_lab_core_v2.json');
    for (final row in sql['tasks'] as List<dynamic>) {
      final item = AnalystTask.fromJson(Map<String, dynamic>.from(row as Map));
      expect(item.solutionText.trim(), isNotEmpty, reason: item.id);
    }

    final sheets = await _asset('assets/content/spreadsheet_cleaning_v1.json');
    for (final row in sheets['challenges'] as List<dynamic>) {
      final item =
          SpreadsheetChallenge.fromJson(Map<String, dynamic>.from(row as Map));
      expect(item.solutionText.trim(), isNotEmpty, reason: item.id);
    }

    for (final path in const [
      'assets/content/pandas_challenges_v1.json',
      'assets/content/pandas_expansion_v1.json',
    ]) {
      final pack = await _asset(path);
      for (final row in pack['challenges'] as List<dynamic>) {
        final item =
            PandasChallenge.fromJson(Map<String, dynamic>.from(row as Map));
        expect(item.solutionText.trim(), isNotEmpty, reason: item.id);
      }
    }

    final analytics = await _asset('assets/content/analytics_studio_v1.json');
    for (final row in analytics['challenges'] as List<dynamic>) {
      final item =
          AnalyticsChallenge.fromJson(Map<String, dynamic>.from(row as Map));
      expect(item.solutionText.trim(), isNotEmpty, reason: item.id);
    }

    final dashboards =
        await _asset('assets/content/dashboard_challenges_v1.json');
    for (final row in dashboards['challenges'] as List<dynamic>) {
      final item =
          DashboardChallenge.fromJson(Map<String, dynamic>.from(row as Map));
      expect(item.solutionText.trim(), isNotEmpty, reason: item.id);
    }
  });
}

Future<Map<String, dynamic>> _asset(String path) async {
  final raw = await rootBundle.loadString(path);
  return jsonDecode(raw) as Map<String, dynamic>;
}
