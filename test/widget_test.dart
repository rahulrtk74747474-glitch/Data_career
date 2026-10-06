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

    // Use finite frames instead of pumpAndSettle because the home screen can
    // legitimately contain animated progress indicators while providers load.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('DataQuest'), findsOneWidget);
    expect(find.text('Today’s tickets'), findsOneWidget);

    // Unmount first so Riverpod disposes providers before the test DB closes.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await database.close();
  });
}
