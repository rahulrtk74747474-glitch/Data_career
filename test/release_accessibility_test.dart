import 'package:dataquest_analyst_career/app.dart';
import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/features/game/game_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  testWidgets('home meets core tap-target and labeling guidelines', (
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
        child: const DataQuestApp(),
      ),
    );
    await tester.pump();
    for (var frame = 0; frame < 40; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('E-commerce Co. • Commercial Analytics').evaluate().isNotEmpty) {
        break;
      }
    }

    await expectLater(
      tester,
      meetsGuideline(androidTapTargetGuideline),
    );
    await expectLater(
      tester,
      meetsGuideline(labeledTapTargetGuideline),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await database.close();
  });
}
