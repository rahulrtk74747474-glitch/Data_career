import 'dart:convert';

import 'package:dataquest_analyst_career/features/game/game_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('notifier advances hospital to logistics then completes journey', () async {
    SharedPreferences.setMockInitialValues({
      'dataquest_progress_v1': jsonEncode({
        'xp': 2600,
        'streak': 0,
        'completedTaskIds': <String>[],
        'revenueIndex': 100,
        'churnRate': 8,
        'costIndex': 100,
        'satisfaction': 70,
        'careerLevel': 5,
        'dailyStreak': 0,
        'lastDailyDate': null,
        'completedDailyDates': <String>[],
        'companyChapter': 3,
        'companyJourneyCompleted': false,
      }),
    });

    final notifier = GameProgressNotifier();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state.companyKey, 'hospital');
    expect(notifier.state.companyJourneyCompleted, isFalse);

    await notifier.advanceCompanyChapter();
    expect(notifier.state.companyKey, 'logistics');
    expect(notifier.state.companyJourneyCompleted, isFalse);

    await notifier.completeCompanyJourney();
    expect(notifier.state.companyJourneyCompleted, isTrue);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('dataquest_progress_v1');
    final saved = jsonDecode(raw!) as Map<String, dynamic>;

    expect(saved['companyChapter'], 4);
    expect(saved['companyJourneyCompleted'], isTrue);
  });
}
