import 'package:flutter/material.dart';

import '../../features/achievements/achievements_screen.dart';
import '../../features/analytics/analytics_studio_screen.dart';
import '../../features/boss_case/boss_case_screen.dart';
import '../../features/continuity/data_continuity_screen.dart';
import '../../features/daily/daily_challenge_screen.dart';
import '../../features/events/random_events_screen.dart';
import '../../features/graduation/job_readiness_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/insight/insight_coach_screen.dart';
import '../../features/interview/interview_mode_screen.dart';
import '../../features/online/weekly_case_screen.dart';
import '../../features/pandas/pandas_lab_screen.dart';
import '../../features/portfolio/portfolio_screen.dart';
import '../../features/practice/practice_gym_screen.dart';
import '../../features/review/monthly_performance_review_screen.dart';
import '../../features/review/review_queue_screen.dart';
import '../../features/spreadsheet/spreadsheet_lab_screen.dart';
import '../../features/sql_workspace/sql_workspace_screen.dart';
import '../../features/splash/splash_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const home = '/home';
  static const practice = '/practice';
  static const review = '/review';
  static const sql = '/sql';
  static const spreadsheet = '/spreadsheet';
  static const pandas = '/pandas';
  static const analytics = '/analytics';
  static const insight = '/insight';
  static const events = '/events';
  static const monthlyReview = '/monthly-review';
  static const daily = '/daily';
  static const weekly = '/weekly';
  static const interview = '/interview';
  static const boss = '/boss';
  static const portfolio = '/portfolio';
  static const achievements = '/achievements';
  static const readiness = '/readiness';
  static const continuity = '/continuity';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget screen = switch (settings.name) {
      splash => const SplashScreen(),
      home => const HomeScreen(),
      practice => const PracticeGymScreen(),
      review => const ReviewQueueScreen(),
      sql => const SqlWorkspaceScreen(),
      spreadsheet => const SpreadsheetLabScreen(),
      pandas => const PandasLabScreen(),
      analytics => const AnalyticsStudioScreen(),
      insight => const InsightCoachScreen(),
      events => const RandomEventsScreen(),
      monthlyReview => const MonthlyPerformanceReviewScreen(),
      daily => const DailyChallengeScreen(),
      weekly => const WeeklyCaseScreen(),
      interview => const InterviewModeScreen(),
      boss => const BossCaseScreen(),
      portfolio => const PortfolioScreen(),
      achievements => const AchievementsScreen(),
      readiness => const JobReadinessScreen(),
      continuity => const DataContinuityScreen(),
      _ => const HomeScreen(),
    };

    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => screen,
    );
  }
}
