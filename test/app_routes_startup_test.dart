import 'package:dataquest_analyst_career/core/navigation/app_routes.dart';
import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/features/game/game_providers.dart';
import 'package:dataquest_analyst_career/services/content_pack_loader.dart';
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

  testWidgets('Splash is the startup route and safely reaches Home', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          contentPackLoaderProvider.overrideWithValue(
            _FastContentPackLoader(database),
          ),
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

    await _waitForHome(tester);

    expect(
      find.text('E-commerce Co. • Commercial Analytics'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await database.close();
  });

  testWidgets('unknown named route falls back to Home', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          contentPackLoaderProvider.overrideWithValue(
            _FastContentPackLoader(database),
          ),
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

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await database.close();
  });
}


Future<void> _waitForHome(WidgetTester tester) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find
        .text('E-commerce Co. • Commercial Analytics')
        .evaluate()
        .isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
}


class _FastContentPackLoader extends ContentPackLoader {
  _FastContentPackLoader(super.database);

  @override
  Future<List<PackInstallResult>> installBundledPacks() async {
    return const [
      PackInstallResult(
        packId: 'test-startup-pack',
        installed: false,
        contentVersion: 1,
      ),
    ];
  }
}
