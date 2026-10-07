import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v1.1 final learning inventory is complete', () {
    final analytics = _json('assets/content/analytics_studio_v1.json');
    final pandasCore = _json('assets/content/pandas_challenges_v1.json');
    final pandasExpansion =
        _json('assets/content/pandas_expansion_v1.json');
    final narrative = _json('assets/content/narrative_v1.json');

    expect(analytics['challenges'] as List<dynamic>, hasLength(15));
    expect(
      <dynamic>[
        ...(pandasCore['challenges'] as List<dynamic>),
        ...(pandasExpansion['challenges'] as List<dynamic>),
      ],
      hasLength(15),
    );
    expect(narrative['insightScenarios'] as List<dynamic>, hasLength(10));
    expect(narrative['managerDialogues'] as List<dynamic>, hasLength(4));
    expect(narrative['events'] as List<dynamic>, hasLength(4));
  });

  test('v1.1 final release/generator surfaces are checked in', () {
    for (final path in const [
      'lib/services/task_pack_generator.dart',
      'tool/generate_task_pack.dart',
      'docs/RELEASE_CHECKLIST_v1_1.md',
      'docs/V1_1_COMPLETION.md',
      'lib/services/portfolio_pdf_export_service.dart',
      'lib/services/cloud_sync_service.dart',
      'lib/features/interview/interview_mode_screen.dart',
      'lib/features/achievements/achievements_screen.dart',
      'lib/features/skills/skills_screen.dart',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
