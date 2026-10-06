import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_settings.dart';
import 'reminder_schedule_planner.dart';

class ReminderApplyResult {
  const ReminderApplyResult({
    required this.permissionGranted,
    required this.scheduledCount,
  });

  final bool permissionGranted;
  final int scheduledCount;
}

abstract interface class ReminderScheduler {
  Future<String?> initialize({
    void Function(String payload)? onPayload,
  });

  Future<ReminderApplyResult> apply(ReminderSettings settings);
}

class LocalNotificationReminderScheduler implements ReminderScheduler {
  LocalNotificationReminderScheduler({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  void Function(String payload)? _onPayload;

  @override
  Future<String?> initialize({
    void Function(String payload)? onPayload,
  }) async {
    if (onPayload != null) {
      _onPayload = onPayload;
    }
    if (_initialized) return null;

    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _onPayload?.call(payload);
        }
      },
    );
    _initialized = true;

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        return payload;
      }
    }
    return null;
  }

  @override
  Future<ReminderApplyResult> apply(ReminderSettings settings) async {
    await initialize();

    for (final id in const [
      ReminderSchedulePlanner.dailyId,
      ReminderSchedulePlanner.reviewId,
    ]) {
      await _plugin.cancel(id: id);
    }

    final plans = ReminderSchedulePlanner.build(settings);
    if (plans.isEmpty) {
      return const ReminderApplyResult(
        permissionGranted: true,
        scheduledCount: 0,
      );
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final permission = await android?.requestNotificationsPermission();
    if (permission == false) {
      return const ReminderApplyResult(
        permissionGranted: false,
        scheduledCount: 0,
      );
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'dataquest_learning_reminders',
        'Learning reminders',
        channelDescription:
            'Daily Challenge and spaced-review reminders chosen by the user.',
      ),
    );

    for (final plan in plans) {
      final now = tz.TZDateTime.now(tz.local);
      var next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        plan.hour,
        plan.minute,
      );
      if (!next.isAfter(now)) {
        next = next.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: plan.id,
        title: plan.title,
        body: plan.body,
        scheduledDate: next,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: plan.payload,
      );
    }

    return ReminderApplyResult(
      permissionGranted: true,
      scheduledCount: plans.length,
    );
  }
}
