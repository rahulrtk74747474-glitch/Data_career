import 'package:dataquest_analyst_career/core/navigation/app_routes.dart';
import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/features/game/game_providers.dart';
import 'package:dataquest_analyst_career/features/splash/splash_screen.dart';
import 'package:dataquest_analyst_career/services/content_pack_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Splash initializes offline storage then replaces itself', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();

    final database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );

    // sqflite_common_ffi performs real asynchronous I/O. Open the database
    // outside Flutter's fake async clock so Splash only waits on an already
    // initialized database during this navigation regression test.
    await tester.runAsync(() => database.database);

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
          appDatabaseProvider.overrideWithValue(database),
          contentPackLoaderProvider.overrideWithValue(
            _NoopContentPackLoader(database),
          ),
        ],
        child: MaterialApp(
          initialRoute: AppRoutes.splash,
          onGenerateRoute: routeFactory,
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Analyst Career'), findsOneWidget);

    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();

    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Home route reached').evaluate().isNotEmpty) break;
    }

    expect(find.text('Home route reached'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await database.close();
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

class _NoopContentPackLoader extends ContentPackLoader {
  _NoopContentPackLoader(super.database);

  @override
  Future<List<PackInstallResult>> installBundledPacks() async => const [];
}
