import 'dart:convert';

import 'package:dataquest_analyst_career/features/game/game_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('legacy progress defaults completed event IDs to empty', () {
    final progress = GameProgress.fromJson({
      'xp': 100,
      'completedTaskIds': <String>[],
      'completedDailyDates': <String>[],
    });

    expect(progress.completedEventIds, isEmpty);
  });

  test('same random event affects company only once', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = GameProgressNotifier();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    await notifier.applyRandomEvent(
      eventId: 'privacy',
      revenueDelta: 1,
      churnDelta: -0.2,
      costDelta: 0.5,
      satisfactionDelta: 2,
    );
    final afterFirst = notifier.state;

    await notifier.applyRandomEvent(
      eventId: 'privacy',
      revenueDelta: 99,
      churnDelta: 99,
      costDelta: 99,
      satisfactionDelta: 99,
    );

    expect(notifier.state.revenueIndex, afterFirst.revenueIndex);
    expect(notifier.state.churnRate, afterFirst.churnRate);
    expect(notifier.state.costIndex, afterFirst.costIndex);
    expect(notifier.state.satisfaction, afterFirst.satisfaction);
    expect(notifier.state.completedEventIds, {'privacy'});

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('dataquest_progress_v1');
    final saved = jsonDecode(raw!) as Map<String, dynamic>;
    expect(saved['completedEventIds'], contains('privacy'));
  });
}
