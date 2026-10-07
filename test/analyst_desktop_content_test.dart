import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('analyst desktop content is complete and decision-rich', () async {
    final raw = await rootBundle.loadString(
      'assets/content/analyst_desktop_v1.json',
    );
    final pack = jsonDecode(raw) as Map<String, dynamic>;

    final inbox = pack['inboxMessages'] as List<dynamic>;
    final handbook = pack['handbookEntries'] as List<dynamic>;
    final metrics = pack['metricCases'] as List<dynamic>;
    final reviews = pack['reviewCases'] as List<dynamic>;
    final stories = pack['stories'] as List<dynamic>;
    final roles = pack['jobRoles'] as List<dynamic>;

    expect(inbox, hasLength(12));
    expect(handbook.length, greaterThanOrEqualTo(34));
    expect(metrics, hasLength(8));
    expect(reviews, hasLength(8));
    expect(stories, hasLength(5));
    expect(roles, hasLength(5));

    for (final rawMessage in inbox) {
      final message = rawMessage as Map;
      final choices = message['choices'] as List<dynamic>;
      expect(choices.length, greaterThanOrEqualTo(3));
      expect(
        choices.any((rawChoice) => (rawChoice as Map)['score'] == 100),
        isTrue,
      );
      expect(
        choices.any((rawChoice) => (rawChoice as Map)['score'] != 100),
        isTrue,
      );
      for (final rawChoice in choices) {
        final choice = rawChoice as Map;
        expect((choice['feedback'] as String).trim(), isNotEmpty);
        expect(choice['impact'], isNotNull);
      }
    }

    for (final rawRole in roles) {
      final role = rawRole as Map;
      final weights = Map<String, dynamic>.from(role['weights'] as Map);
      final total = weights.values.fold<double>(
        0,
        (sum, value) => sum + (value as num).toDouble(),
      );
      expect(total, closeTo(1, 0.0001));
    }
  });
}
