import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/features/game/game_providers.dart';
import 'package:dataquest_analyst_career/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  testWidgets('DataQuest home screen renders the starting career state', (
    tester,
  ) async {
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
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();
    expect(find.text('DataQuest'), findsOneWidget);
    expect(
      find.text('E-commerce Co. • Commercial Analytics'),
      findsOneWidget,
    );
    expect(find.text('Data Analyst Intern'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);

    await tester.drag(
      find.byType(ListView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(find.text('Learning labs'), findsOneWidget);
    expect(find.text('Core analyst labs'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await database.close();
  });
}
