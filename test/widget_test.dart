import 'package:dataquest_analyst_career/app.dart';
import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/features/game/game_providers.dart';
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

    await tester.pumpAndSettle();

    expect(find.text('DataQuest'), findsOneWidget);
    expect(find.text('Today’s tickets'), findsOneWidget);

    await database.close();
  });
}
