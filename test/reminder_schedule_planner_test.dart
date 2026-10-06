import 'package:dataquest_analyst_career/models/reminder_settings.dart';
import 'package:dataquest_analyst_career/services/reminder_schedule_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('disabled reminders create no schedule plans', () {
    final plans = ReminderSchedulePlanner.build(
      ReminderSettings.defaults(),
    );

    expect(plans, isEmpty);
  });

  test('enabled reminders preserve user-selected local clock times', () {
    const settings = ReminderSettings(
      dailyEnabled: true,
      reviewEnabled: true,
      dailyHour: 7,
      dailyMinute: 30,
      reviewHour: 20,
      reviewMinute: 15,
    );

    final plans = ReminderSchedulePlanner.build(settings);

    expect(plans, hasLength(2));
    expect(plans[0].id, ReminderSchedulePlanner.dailyId);
    expect(plans[0].kind, ReminderKind.dailyChallenge);
    expect(plans[0].hour, 7);
    expect(plans[0].minute, 30);
    expect(plans[1].id, ReminderSchedulePlanner.reviewId);
    expect(plans[1].kind, ReminderKind.reviewQueue);
    expect(plans[1].hour, 20);
    expect(plans[1].minute, 15);
  });

  test('settings parser clamps invalid stored times to safe defaults', () {
    final settings = ReminderSettings.fromJson({
      'dailyEnabled': true,
      'reviewEnabled': true,
      'dailyHour': 99,
      'dailyMinute': -1,
      'reviewHour': -4,
      'reviewMinute': 100,
    });

    expect(settings.dailyHour, 18);
    expect(settings.dailyMinute, 0);
    expect(settings.reviewHour, 19);
    expect(settings.reviewMinute, 0);
  });
}
