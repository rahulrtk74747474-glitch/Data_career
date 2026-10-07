import 'dart:io';

import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late String path;

  setUp(() async {
    sqfliteFfiInit();
    tempDir = await Directory.systemTemp.createTemp('dataquest-v9-migration-');
    path = '${tempDir.path}/legacy.db';
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('v9 -> v10 migration preserves player/catalog state', () async {
    final legacy = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 9,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users (
              user_id TEXT PRIMARY KEY,
              display_name TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE progress (
              user_id TEXT PRIMARY KEY,
              xp INTEGER NOT NULL DEFAULT 0,
              career_level INTEGER NOT NULL DEFAULT 0,
              company_chapter INTEGER NOT NULL DEFAULT 0,
              daily_streak INTEGER NOT NULL DEFAULT 0,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE content_packs (
              pack_id TEXT PRIMARY KEY,
              schema_version INTEGER NOT NULL,
              content_version INTEGER NOT NULL,
              source_asset TEXT NOT NULL,
              installed_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE tasks (
              task_id TEXT PRIMARY KEY,
              pack_id TEXT NOT NULL,
              title TEXT NOT NULL,
              skill_key TEXT NOT NULL,
              difficulty TEXT NOT NULL,
              company_key TEXT NOT NULL,
              answer_type TEXT NOT NULL,
              content_version INTEGER NOT NULL,
              json_payload TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE datasets (
              dataset_id TEXT PRIMARY KEY,
              pack_id TEXT NOT NULL,
              name TEXT NOT NULL,
              content_version INTEGER NOT NULL,
              json_payload TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE dialogues (
              dialogue_id TEXT PRIMARY KEY,
              pack_id TEXT NOT NULL,
              trigger_key TEXT NOT NULL,
              content_version INTEGER NOT NULL,
              json_payload TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE rubrics (
              rubric_id TEXT PRIMARY KEY,
              pack_id TEXT NOT NULL,
              kind TEXT NOT NULL,
              content_version INTEGER NOT NULL,
              json_payload TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE attempts (
              attempt_id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id TEXT NOT NULL,
              task_id TEXT NOT NULL,
              score INTEGER NOT NULL,
              answer_json TEXT NOT NULL,
              completed_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE events (
              event_id TEXT PRIMARY KEY,
              pack_id TEXT NOT NULL,
              event_type TEXT NOT NULL,
              content_version INTEGER NOT NULL,
              json_payload TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE achievements (
              achievement_id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT NOT NULL,
              rule_json TEXT NOT NULL,
              content_version INTEGER NOT NULL
            )
          ''');
        },
      ),
    );

    await legacy.insert('users', {
      'user_id': 'local-player',
      'display_name': 'Existing Player',
      'created_at': '2026-10-01T00:00:00Z',
    });
    await legacy.insert('progress', {
      'user_id': 'local-player',
      'xp': 4321,
      'career_level': 4,
      'company_chapter': 3,
      'daily_streak': 9,
      'updated_at': '2026-10-06T00:00:00Z',
    });
    await legacy.insert('content_packs', {
      'pack_id': 'legacy-pack',
      'schema_version': 1,
      'content_version': 1,
      'source_asset': 'legacy.json',
      'installed_at': '2026-10-01T00:00:00Z',
    });
    await legacy.insert('tasks', {
      'task_id': 'legacy-task',
      'pack_id': 'legacy-pack',
      'title': 'Legacy task',
      'skill_key': 'sql',
      'difficulty': 'Beginner',
      'company_key': 'ecommerce',
      'answer_type': 'choice',
      'content_version': 1,
      'json_payload': '{}',
    });
    await legacy.insert('attempts', {
      'user_id': 'local-player',
      'task_id': 'legacy-task',
      'score': 90,
      'answer_json': '{"answer":"A"}',
      'completed_at': '2026-10-06T00:00:00Z',
    });
    await legacy.insert('achievements', {
      'achievement_id': 'legacy-badge',
      'title': 'Legacy badge',
      'description': 'Already present before migration.',
      'rule_json': '{}',
      'content_version': 1,
    });
    await legacy.close();

    final appDatabase = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: path,
    );
    final db = await appDatabase.database;

    final progress = await db.query(
      'progress',
      where: 'user_id = ?',
      whereArgs: ['local-player'],
    );
    final tasks = await db.query(
      'tasks',
      where: 'task_id = ?',
      whereArgs: ['legacy-task'],
    );
    final attempts = await db.query('attempts');
    final achievements = await db.query(
      'achievements',
      where: 'achievement_id = ?',
      whereArgs: ['legacy-badge'],
    );

    expect(progress.single['xp'], 4321);
    expect(progress.single['career_level'], 4);
    expect(tasks.single['is_active'], 1);
    expect(attempts.single['score'], 90);
    expect(attempts.single['task_content_version'], 1);
    expect(achievements.single['title'], 'Legacy badge');
    expect(achievements.single['pack_id'], isNull);
    expect(achievements.single['is_active'], 1);

    final version = await db.rawQuery('PRAGMA user_version');
    expect(version.single['user_version'], 10);

    await appDatabase.close();
  });
}
