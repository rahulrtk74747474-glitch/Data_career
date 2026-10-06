import 'dart:convert';

import 'package:dataquest_analyst_career/services/cloud_sync_service.dart';
import 'package:dataquest_analyst_career/services/weekly_case_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const config = CloudRuntimeConfig(
    supabaseUrl: '',
    supabaseAnonKey: '',
    weeklyCaseUrl: 'https://example.test/weekly.json',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('valid online weekly case is accepted and cached', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode(_pack(title: 'Fresh online case')),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = WeeklyCaseService(config: config, client: client);

    final result = await service.load(refresh: true);

    expect(result.source, 'online');
    expect(result.pack.title, 'Fresh online case');
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('dataquest_weekly_case_cache_v1'),
      contains('Fresh online case'),
    );
    service.close();
  });

  test('server failure falls back to last valid cached pack', () async {
    SharedPreferences.setMockInitialValues({
      'dataquest_weekly_case_cache_v1': jsonEncode(
        _pack(title: 'Cached safe case'),
      ),
    });
    final client = MockClient((request) async {
      return http.Response('temporary outage', 503);
    });
    final service = WeeklyCaseService(config: config, client: client);

    final result = await service.load(refresh: true);

    expect(result.source, 'cache');
    expect(result.pack.title, 'Cached safe case');
    expect(result.message, contains('last valid cached pack'));
    service.close();
  });

  test('invalid newer online schema never replaces valid cache', () async {
    SharedPreferences.setMockInitialValues({
      'dataquest_weekly_case_cache_v1': jsonEncode(
        _pack(title: 'Known valid cache'),
      ),
    });
    final client = MockClient((request) async {
      final invalid = _pack(title: 'Unsupported remote')
        ..['schemaVersion'] = 999;
      return http.Response(jsonEncode(invalid), 200);
    });
    final service = WeeklyCaseService(config: config, client: client);

    final result = await service.load(refresh: true);

    expect(result.source, 'cache');
    expect(result.pack.title, 'Known valid cache');
    service.close();
  });
}

Map<String, dynamic> _pack({required String title}) {
  return {
    'schemaVersion': 1,
    'caseId': 'case-1',
    'weekKey': '2026-W41',
    'title': title,
    'context': 'Synthetic business context.',
    'prompt': 'What should the analyst do?',
    'options': ['Validate data first', 'Guess from one row'],
    'expectedAnswer': 'Validate data first',
    'explanation': 'Validation protects the analysis.',
  };
}
