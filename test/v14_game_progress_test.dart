import 'dart:convert';

import 'package:dataquest_analyst_career/features/game/game_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('v1.4 company impact and manual notes survive serialization', () {
    final progress = GameProgress.initial().copyWith(
      managerTrust: 77,
      dataQuality: 82,
      riskIndex: 31,
      manualNotes: ['Check denominator before interpreting a rate.'],
    );

    final restored = GameProgress.fromJson(progress.toJson());

    expect(restored.managerTrust, 77);
    expect(restored.dataQuality, 82);
    expect(restored.riskIndex, 31);
    expect(restored.manualNotes, hasLength(1));
  });

  test('work decision applies consequences only once', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = GameProgressNotifier();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final xp = await notifier.applyWorkDecision(
      decisionId: 'test-decision',
      baseXp: 30,
      score: 100,
      trustDelta: 4,
      dataQualityDelta: 3,
      riskDelta: -2,
    );
    final first = notifier.state;

    final secondXp = await notifier.applyWorkDecision(
      decisionId: 'test-decision',
      baseXp: 30,
      score: 100,
      trustDelta: 99,
      dataQualityDelta: 99,
      riskDelta: 99,
    );

    expect(xp, 30);
    expect(secondXp, 0);
    expect(notifier.state.managerTrust, first.managerTrust);
    expect(notifier.state.dataQuality, first.dataQuality);
    expect(notifier.state.riskIndex, first.riskIndex);
    expect(
      notifier.state.rewardedLearningIds,
      contains('decision:test-decision'),
    );

    await notifier.addManualNote('  Revenue is not profit.  ');
    expect(notifier.state.manualNotes, ['Revenue is not profit.']);

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(
      prefs.getString('dataquest_progress_v1')!,
    ) as Map<String, dynamic>;
    expect(saved['manualNotes'], contains('Revenue is not profit.'));
  });
}
