import 'dart:convert';

import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/services/content_pack_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late ContentPackLoader loader;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
    loader = ContentPackLoader(database);
  });

  tearDown(() => database.close());

  test('installs the bundled schema-v2 pack offline', () async {
    final results = await loader.installBundledPacks();
    final db = await database.database;

    expect(results, hasLength(1));
    expect(results.single.installed, isTrue);
    expect(results.single.contentVersion, 2);
    expect(await db.query('tasks', where: 'is_active = 1'), hasLength(5));
    expect(await db.query('datasets', where: 'is_active = 1'), hasLength(4));
    expect(await db.query('rubrics', where: 'is_active = 1'), hasLength(5));
  });

  test('installs a valid pack into the offline catalog', () async {
    final result = await loader.installRaw(
      jsonEncode(_pack(version: 1, title: 'Version one')),
      sourceAsset: 'test.json',
    );
    final db = await database.database;
    final tasks = await db.query('tasks');

    expect(result.installed, isTrue);
    expect(result.contentVersion, 1);
    expect(tasks, hasLength(1));
    expect(tasks.single['title'], 'Version one');
    expect(tasks.single['is_active'], 1);
  });

  test('upgrade is idempotent, preserves attempts and retires removed rows',
      () async {
    await loader.installRaw(
      jsonEncode(
        _pack(
          version: 1,
          title: 'Version one',
          includeSecondTask: true,
        ),
      ),
      sourceAsset: 'v1.json',
    );
    final db = await database.database;
    await db.insert('attempts', {
      'user_id': 'local-player',
      'task_id': 'task-1',
      'task_content_version': 1,
      'score': 80,
      'answer_json': '{"answer":"A"}',
      'completed_at': '2026-10-07T00:00:00Z',
    });

    final same = await loader.installRaw(
      jsonEncode(_pack(version: 1, title: 'Should not replace')),
      sourceAsset: 'same.json',
    );
    final upgraded = await loader.installRaw(
      jsonEncode(_pack(version: 2, title: 'Version two')),
      sourceAsset: 'v2.json',
    );

    final current = await db.query(
      'tasks',
      where: 'task_id = ?',
      whereArgs: ['task-1'],
    );
    final retired = await db.query(
      'tasks',
      where: 'task_id = ?',
      whereArgs: ['task-2'],
    );
    final attempts = await db.query('attempts');

    expect(same.installed, isFalse);
    expect(upgraded.installed, isTrue);
    expect(upgraded.contentVersion, 2);
    expect(current.single['title'], 'Version two');
    expect(current.single['is_active'], 1);
    expect(retired.single['is_active'], 0);
    expect(attempts, hasLength(1));
    expect(attempts.single['task_content_version'], 1);
  });

  test('unsupported pack schema is rejected before catalog mutation', () async {
    final invalid = _pack(version: 1, title: 'Invalid')
      ..['schemaVersion'] = 999;

    await expectLater(
      loader.installRaw(
        jsonEncode(invalid),
        sourceAsset: 'invalid.json',
      ),
      throwsA(isA<FormatException>()),
    );

    final db = await database.database;
    expect(await db.query('content_packs'), isEmpty);
  });

  test('schema-v2 task must contain exactly three hints', () async {
    final invalid = _pack(version: 1, title: 'Invalid');
    final task =
        Map<String, dynamic>.from((invalid['tasks'] as List).single as Map);
    task['hints'] = ['Only one hint'];
    invalid['tasks'] = [task];

    await expectLater(
      loader.installRaw(
        jsonEncode(invalid),
        sourceAsset: 'invalid-hints.json',
      ),
      throwsA(isA<FormatException>()),
    );

    final db = await database.database;
    expect(await db.query('content_packs'), isEmpty);
  });

  test('transaction rollback keeps previous pack intact on SQLite failure',
      () async {
    await loader.installRaw(
      jsonEncode(_pack(version: 1, title: 'Stable version')),
      sourceAsset: 'stable.json',
    );
    final db = await database.database;
    await db.execute('''
      CREATE TRIGGER fail_event_insert
      BEFORE INSERT ON events
      WHEN NEW.event_id = 'event-fail'
      BEGIN
        SELECT RAISE(ABORT, 'forced test failure');
      END
    ''');

    final broken = _pack(version: 2, title: 'Must roll back');
    broken['events'] = [
      {
        'id': 'event-fail',
        'eventType': 'quality',
        'title': 'Forced failure',
        'description': 'Used only to verify transaction rollback.',
        'decision': 'The old pack must remain intact.',
      },
    ];

    await expectLater(
      loader.installRaw(
        jsonEncode(broken),
        sourceAsset: 'broken-v2.json',
      ),
      throwsA(anything),
    );

    final task = await db.query(
      'tasks',
      where: 'task_id = ?',
      whereArgs: ['task-1'],
    );
    final pack = await db.query(
      'content_packs',
      where: 'pack_id = ?',
      whereArgs: ['test-pack'],
    );
    final event = await db.query(
      'events',
      where: 'event_id = ?',
      whereArgs: ['event-1'],
    );

    expect(task.single['title'], 'Stable version');
    expect(task.single['is_active'], 1);
    expect(pack.single['content_version'], 1);
    expect(event.single['is_active'], 1);
  });
}

Map<String, dynamic> _pack({
  required int version,
  required String title,
  bool includeSecondTask = false,
}) {
  final tasks = <Map<String, dynamic>>[
    _task('task-1', title),
    if (includeSecondTask) _task('task-2', 'Retirable task'),
  ];
  return {
    'packId': 'test-pack',
    'schemaVersion': 2,
    'contentVersion': version,
    'datasets': [
      {
        'id': 'dataset-1',
        'name': 'Sample',
        'columns': ['value'],
        'rows': [
          {'value': 1},
        ],
      },
    ],
    'dialogues': [
      {
        'id': 'dialogue-1',
        'triggerKey': 'start',
        'speaker': 'Manager',
        'text': 'Hello',
      },
    ],
    'rubrics': [
      {
        'id': 'rubric-1',
        'kind': 'choice',
        'criteria': [
          {'key': 'correct', 'weight': 100},
        ],
      },
    ],
    'events': [
      {
        'id': 'event-1',
        'eventType': 'quality',
        'title': 'Event',
        'description': 'A test event.',
        'decision': 'Validate before acting.',
      },
    ],
    'achievements': [
      {
        'id': 'badge-1',
        'title': 'Badge',
        'description': 'Test badge',
        'rule': {'type': 'test'},
      },
    ],
    'tasks': tasks,
  };
}

Map<String, dynamic> _task(String id, String title) {
  return {
    'id': id,
    'title': title,
    'skillKey': 'sql',
    'difficulty': 'Beginner',
    'companyKey': 'ecommerce',
    'answerType': 'choice',
    'context': 'Test business context.',
    'prompt': 'Choose the correct answer.',
    'datasetId': 'dataset-1',
    'rubricId': 'rubric-1',
    'expectedAnswer': 'A',
    'options': ['A', 'B'],
    'hints': ['Hint one', 'Hint two', 'Hint three'],
  };
}
