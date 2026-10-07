import 'package:dataquest_analyst_career/app.dart';
import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/features/game/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  testWidgets('DataQuest home screen starts', (tester) async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();

    final database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
        ],
        child: const DataQuestApp(),
      ),
    );

    // Startup now migrates SQLite and installs bundled versioned content
    // before routing from Splash to Home. Pump finite frames because provider
    // progress indicators can legitimately remain animated on Home.
    await tester.pump();
    await _waitForHome(tester);

    expect(find.text('DataQuest'), findsWidgets);
    expect(find.text('E-commerce Co. • Commercial Analytics'), findsOneWidget);
    expect(find.text('Data Analyst Intern'), findsOneWidget);

    final db = await database.database;
    final packs = await db.query(
      'content_packs',
      where: 'pack_id = ?',
      whereArgs: ['mvp-sample-core'],
    );
    expect(packs, hasLength(1));

    // Unmount first so Riverpod disposes providers before the test DB closes.
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
