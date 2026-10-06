import 'dart:convert';

import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/services/content_pack_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
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
  });

  test('same version is skipped and newer version replaces pack rows', () async {
    await loader.installRaw(
      jsonEncode(_pack(version: 1, title: 'Version one')),
      sourceAsset: 'v1.json',
    );
    final same = await loader.installRaw(
      jsonEncode(_pack(version: 1, title: 'Should not replace')),
      sourceAsset: 'same.json',
    );
    final upgraded = await loader.installRaw(
      jsonEncode(_pack(version: 2, title: 'Version two')),
      sourceAsset: 'v2.json',
    );

    final db = await database.database;
    final tasks = await db.query('tasks');

    expect(same.installed, isFalse);
    expect(upgraded.installed, isTrue);
    expect(upgraded.contentVersion, 2);
    expect(tasks, hasLength(1));
    expect(tasks.single['title'], 'Version two');
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
}

Map<String, dynamic> _pack({
  required int version,
  required String title,
}) {
  return {
    'packId': 'test-pack',
    'schemaVersion': 1,
    'contentVersion': version,
    'datasets': [
      {
        'id': 'dataset-1',
        'name': 'Sample',
        'rows': [
          {'value': 1},
        ],
      },
    ],
    'dialogues': [
      {
        'id': 'dialogue-1',
        'triggerKey': 'start',
        'text': 'Hello',
      },
    ],
    'rubrics': [
      {
        'id': 'rubric-1',
        'kind': 'insight',
        'criteria': [],
      },
    ],
    'events': [
      {
        'id': 'event-1',
        'eventType': 'quality',
        'title': 'Event',
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
    'tasks': [
      {
        'id': 'task-1',
        'title': title,
        'skillKey': 'sql',
        'difficulty': 'Beginner',
        'companyKey': 'ecommerce',
        'answerType': 'choice',
      },
    ],
  };
}
