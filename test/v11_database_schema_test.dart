import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
  });

  tearDown(() => database.close());

  test('v9 database contains requested canonical content tables', () async {
    final db = await database.database;
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    final names = rows.map((row) => row['name']).toSet();

    expect(AppDatabase.schemaVersion, 9);
    expect(
      names,
      containsAll({
        'users',
        'progress',
        'tasks',
        'datasets',
        'attempts',
        'events',
        'achievements',
        'content_packs',
        'dialogues',
        'rubrics',
        'user_achievements',
      }),
    );
  });

  test('synthetic SaaS monthly table seeds 15 rows', () async {
    final db = await database.database;
    final rows = await db.query('saas_account_monthly');

    expect(rows, hasLength(15));
    expect(
      rows.where((row) => row['active'] == 0).length,
      1,
    );
  });

  test('local content-catalog user is created without deleting old state tables', () async {
    final db = await database.database;
    final users = await db.query('users');
    final skillRows = await db.query('skill_mastery');

    expect(users.single['user_id'], 'local-player');
    expect(skillRows, isNotEmpty);
  });
}
