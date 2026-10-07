import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('zero-to-analyst academy has 80 complete job-ready foundation lessons', () async {
    final raw =
        await rootBundle.loadString('assets/content/foundation_academy_v1.json');
    final pack = jsonDecode(raw) as Map<String, dynamic>;
    final lessons = pack['lessons'] as List<dynamic>;

    expect(lessons, hasLength(80));
    final trackCounts = <String, int>{};

    for (final rawLesson in lessons) {
      final lesson = Map<String, dynamic>.from(rawLesson as Map);
      final track = lesson['trackKey'] as String;
      trackCounts[track] = (trackCounts[track] ?? 0) + 1;

      expect((lesson['scenario'] as String).trim(), isNotEmpty);
      expect((lesson['workedExample'] as String).trim(), isNotEmpty);
      expect((lesson['solution'] as String).trim(), isNotEmpty);
      expect(lesson['hints'] as List<dynamic>, hasLength(3));
      expect(
        lesson['options'] as List<dynamic>,
        contains(lesson['correctAnswer']),
      );
    }

    expect(trackCounts, {
      'sql': 10,
      'spreadsheets': 10,
      'cleaning': 10,
      'statistics': 12,
      'python': 12,
      'dashboards': 10,
      'powerbi': 8,
      'business': 8,
    });
  });
}
