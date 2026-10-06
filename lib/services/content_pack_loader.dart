import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../models/content_pack.dart';

class PackInstallResult {
  const PackInstallResult({
    required this.packId,
    required this.installed,
    required this.contentVersion,
  });

  final String packId;
  final bool installed;
  final int contentVersion;
}

class ContentPackLoader {
  const ContentPackLoader(this._database);

  static const bundledAssets = <String>[
    'assets/content/content_pack_sample_v1.json',
  ];

  final AppDatabase _database;

  Future<List<PackInstallResult>> installBundledPacks() async {
    final results = <PackInstallResult>[];
    for (final asset in bundledAssets) {
      final raw = await rootBundle.loadString(asset);
      results.add(await installRaw(raw, sourceAsset: asset));
    }
    return results;
  }

  Future<PackInstallResult> installRaw(
    String raw, {
    required String sourceAsset,
  }) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Content-pack root must be an object.');
    }

    final pack = ContentPack.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    final db = await _database.database;

    final existing = await db.query(
      'content_packs',
      columns: ['content_version'],
      where: 'pack_id = ?',
      whereArgs: [pack.packId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final installedVersion =
          (existing.first['content_version'] as num).toInt();
      if (installedVersion >= pack.contentVersion) {
        return PackInstallResult(
          packId: pack.packId,
          installed: false,
          contentVersion: installedVersion,
        );
      }
    }

    await db.transaction((txn) async {
      for (final table in const [
        'tasks',
        'datasets',
        'dialogues',
        'rubrics',
        'events',
      ]) {
        await txn.delete(
          table,
          where: 'pack_id = ?',
          whereArgs: [pack.packId],
        );
      }

      await txn.insert(
        'content_packs',
        {
          'pack_id': pack.packId,
          'schema_version': pack.schemaVersion,
          'content_version': pack.contentVersion,
          'source_asset': sourceAsset,
          'installed_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final task in pack.tasks) {
        _require(task, const [
          'id',
          'title',
          'skillKey',
          'difficulty',
          'companyKey',
          'answerType',
        ], 'task');
        await txn.insert(
          'tasks',
          {
            'task_id': task['id'],
            'pack_id': pack.packId,
            'title': task['title'],
            'skill_key': task['skillKey'],
            'difficulty': task['difficulty'],
            'company_key': task['companyKey'],
            'answer_type': task['answerType'],
            'content_version': pack.contentVersion,
            'json_payload': jsonEncode(task),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final dataset in pack.datasets) {
        _require(dataset, const ['id', 'name'], 'dataset');
        await txn.insert(
          'datasets',
          {
            'dataset_id': dataset['id'],
            'pack_id': pack.packId,
            'name': dataset['name'],
            'content_version': pack.contentVersion,
            'json_payload': jsonEncode(dataset),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final dialogue in pack.dialogues) {
        _require(dialogue, const ['id', 'triggerKey'], 'dialogue');
        await txn.insert(
          'dialogues',
          {
            'dialogue_id': dialogue['id'],
            'pack_id': pack.packId,
            'trigger_key': dialogue['triggerKey'],
            'content_version': pack.contentVersion,
            'json_payload': jsonEncode(dialogue),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final rubric in pack.rubrics) {
        _require(rubric, const ['id', 'kind'], 'rubric');
        await txn.insert(
          'rubrics',
          {
            'rubric_id': rubric['id'],
            'pack_id': pack.packId,
            'kind': rubric['kind'],
            'content_version': pack.contentVersion,
            'json_payload': jsonEncode(rubric),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final event in pack.events) {
        _require(event, const ['id', 'eventType'], 'event');
        await txn.insert(
          'events',
          {
            'event_id': event['id'],
            'pack_id': pack.packId,
            'event_type': event['eventType'],
            'content_version': pack.contentVersion,
            'json_payload': jsonEncode(event),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final achievement in pack.achievements) {
        _require(
          achievement,
          const ['id', 'title', 'description', 'rule'],
          'achievement',
        );
        await txn.insert(
          'achievements',
          {
            'achievement_id': achievement['id'],
            'title': achievement['title'],
            'description': achievement['description'],
            'rule_json': jsonEncode(achievement['rule']),
            'content_version': pack.contentVersion,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    return PackInstallResult(
      packId: pack.packId,
      installed: true,
      contentVersion: pack.contentVersion,
    );
  }

  static void _require(
    Map<String, dynamic> row,
    List<String> keys,
    String label,
  ) {
    for (final key in keys) {
      final value = row[key];
      if (value == null || value.toString().trim().isEmpty) {
        throw FormatException('$label is missing required field $key.');
      }
    }
  }
}
