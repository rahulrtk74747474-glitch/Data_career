import '../models/reminder_settings.dart';

enum ReminderKind { dailyChallenge, reviewQueue }

class ReminderPlan {
  const ReminderPlan({
    required this.id,
    required this.kind,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final ReminderKind kind;
  final int hour;
  final int minute;
  final String title;
  final String body;
  final String payload;
}

class ReminderSchedulePlanner {
  const ReminderSchedulePlanner._();

  static const dailyId = 7101;
  static const reviewId = 7102;

  static List<ReminderPlan> build(ReminderSettings settings) {
    final plans = <ReminderPlan>[];

    if (settings.dailyEnabled) {
      plans.add(
        ReminderPlan(
          id: dailyId,
          kind: ReminderKind.dailyChallenge,
          hour: settings.dailyHour,
          minute: settings.dailyMinute,
          title: 'DataQuest Daily Challenge',
          body: 'Your daily analyst challenge is ready. Keep the streak alive.',
          payload: 'daily_challenge',
        ),
      );
    }

    if (settings.reviewEnabled) {
      plans.add(
        ReminderPlan(
          id: reviewId,
          kind: ReminderKind.reviewQueue,
          hour: settings.reviewHour,
          minute: settings.reviewMinute,
          title: 'DataQuest Review Queue',
          body: 'Review weak or due analyst skills before they fade.',
          payload: 'review_queue',
        ),
      );
    }

    return plans;
  }
}
