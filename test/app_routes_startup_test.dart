import 'package:dataquest_analyst_career/core/navigation/app_routes.dart';
import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/features/game/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('Splash is the startup route and safely reaches Home', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Analyst Career'), findsOneWidget);
    expect(find.text('Opening offline workspace...'), findsOneWidget);

    for (var frame = 0; frame < 200; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('E-commerce Co. • Commercial Analytics')
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(
      find.text('E-commerce Co. • Commercial Analytics'),
      findsOneWidget,
    );
  });

  testWidgets('unknown named route falls back to Home', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
        ],
        child: MaterialApp(
          initialRoute: '/unknown-route',
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('E-commerce Co. • Commercial Analytics'), findsOneWidget);
  });
}
