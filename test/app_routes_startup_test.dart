import 'package:dataquest_analyst_career/core/navigation/app_routes.dart';
import 'package:dataquest_analyst_career/features/game/game_providers.dart';
import 'package:dataquest_analyst_career/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Splash completes startup and navigates to Home', (
    tester,
  ) async {
    Route<dynamic> routeFactory(RouteSettings settings) {
      if (settings.name == AppRoutes.splash) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      }
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const Scaffold(
          body: Center(child: Text('Home route reached')),
        ),
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          startupInitializationProvider.overrideWith((ref) async {}),
        ],
        child: MaterialApp(
          initialRoute: AppRoutes.splash,
          onGenerateRoute: routeFactory,
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Analyst Career'), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Home route reached'), findsOneWidget);
  });

  test('central route factory registers every primary route name', () {
    const names = [
      AppRoutes.splash,
      AppRoutes.home,
      AppRoutes.practice,
      AppRoutes.review,
      AppRoutes.sql,
      AppRoutes.spreadsheet,
      AppRoutes.pandas,
      AppRoutes.analytics,
      AppRoutes.insight,
      AppRoutes.events,
      AppRoutes.monthlyReview,
      AppRoutes.daily,
      AppRoutes.weekly,
      AppRoutes.interview,
      AppRoutes.boss,
      AppRoutes.portfolio,
      AppRoutes.achievements,
      AppRoutes.readiness,
      AppRoutes.continuity,
    ];

    for (final name in names) {
      final route = AppRoutes.onGenerateRoute(RouteSettings(name: name));
      expect(route, isA<MaterialPageRoute<dynamic>>());
      expect(route.settings.name, name);
    }
  });
}

