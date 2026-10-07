import 'package:dataquest_analyst_career/app.dart';
import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/features/game/game_providers.dart';
import 'package:dataquest_analyst_career/services/content_pack_loader.dart';
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

    await tester.runAsync(() => database.database);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          contentPackLoaderProvider.overrideWithValue(
            _NoopContentPackLoader(database),
          ),
        ],
        child: const DataQuestApp(),
      ),
    );

    await tester.pump();
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find
          .text('E-commerce Co. • Commercial Analytics')
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.text('DataQuest'), findsWidgets);
    expect(
      find.text('E-commerce Co. • Commercial Analytics'),
      findsOneWidget,
    );
    expect(find.text('Data Analyst Intern'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await database.close();
  });
}

class _NoopContentPackLoader extends ContentPackLoader {
  _NoopContentPackLoader(super.database);

  @override
  Future<List<PackInstallResult>> installBundledPacks() async => const [];
}
