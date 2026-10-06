import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/daily/daily_challenge_screen.dart';
import 'features/game/game_providers.dart';
import 'features/home/home_screen.dart';
import 'features/review/review_queue_screen.dart';
import 'services/notification_destination_service.dart';

class DataQuestApp extends ConsumerStatefulWidget {
  const DataQuestApp({super.key});

  @override
  ConsumerState<DataQuestApp> createState() => _DataQuestAppState();
}

class _DataQuestAppState extends ConsumerState<DataQuestApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final launchPayload =
            await ref.read(reminderSchedulerProvider).initialize(
                  onPayload: _openNotificationPayload,
                );
        if (launchPayload != null && mounted) {
          _openNotificationPayload(launchPayload);
        }
      } catch (_) {
        // Reminder support must never prevent the offline learning app
        // from starting on unsupported/test platforms.
      }
    });
  }

  void _openNotificationPayload(String payload) {
    if (!mounted) return;

    final destination = NotificationDestinationService.resolve(payload);
    if (destination == null) return;

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openNotificationPayload(payload),
      );
      return;
    }

    final Widget screen = switch (destination) {
      NotificationDestination.dailyChallenge =>
        const DailyChallengeScreen(),
      NotificationDestination.reviewQueue => const ReviewQueueScreen(),
    };

    navigator.push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'DataQuest: Analyst Career',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
