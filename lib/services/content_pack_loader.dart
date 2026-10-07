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
    if (sourceAsset.trim().isEmpty) {
      throw const FormatException('Content pack sourceAsset is required.');
    }

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

    await _validateOwnership(db, 'tasks', 'task_id', pack.packId, pack.tasks);
    await _validateOwnership(
      db,
      'datasets',
      'dataset_id',
      pack.packId,
      pack.datasets,
    );
    await _validateOwnership(
      db,
      'dialogues',
      'dialogue_id',
      pack.packId,
      pack.dialogues,
    );
    await _validateOwnership(
      db,
      'rubrics',
      'rubric_id',
      pack.packId,
      pack.rubrics,
    );
    await _validateOwnership(db, 'events', 'event_id', pack.packId, pack.events);
    await _validateOwnership(
      db,
      'achievements',
      'achievement_id',
      pack.packId,
      pack.achievements,
    );

    await db.transaction((txn) async {
      for (final table in const [
        'tasks',
        'datasets',
        'dialogues',
        'rubrics',
        'events',
        'achievements',
      ]) {
        await txn.update(
          table,
          {'is_active': 0},
          where: 'pack_id = ?',
          whereArgs: [pack.packId],
        );
      }

      await _upsertByKey(
        txn,
        table: 'content_packs',
        keyColumn: 'pack_id',
        keyValue: pack.packId,
        values: {
          'pack_id': pack.packId,
          'schema_version': pack.schemaVersion,
          'content_version': pack.contentVersion,
          'source_asset': sourceAsset,
          'installed_at': DateTime.now().toUtc().toIso8601String(),
        },
      );

      for (final task in pack.tasks) {
        await _upsertByKey(
          txn,
          table: 'tasks',
          keyColumn: 'task_id',
          keyValue: task['id'],
          values: {
            'task_id': task['id'],
            'pack_id': pack.packId,
            'title': task['title'],
            'skill_key': task['skillKey'],
            'difficulty': task['difficulty'],
            'company_key': task['companyKey'],
            'answer_type': task['answerType'],
            'content_version': pack.contentVersion,
            'is_active': 1,
            'json_payload': jsonEncode(task),
          },
        );
      }

      for (final dataset in pack.datasets) {
        await _upsertByKey(
          txn,
          table: 'datasets',
          keyColumn: 'dataset_id',
          keyValue: dataset['id'],
          values: {
            'dataset_id': dataset['id'],
            'pack_id': pack.packId,
            'name': dataset['name'],
            'content_version': pack.contentVersion,
            'is_active': 1,
            'json_payload': jsonEncode(dataset),
          },
        );
      }

      for (final dialogue in pack.dialogues) {
        await _upsertByKey(
          txn,
          table: 'dialogues',
          keyColumn: 'dialogue_id',
          keyValue: dialogue['id'],
          values: {
            'dialogue_id': dialogue['id'],
            'pack_id': pack.packId,
            'trigger_key': dialogue['triggerKey'],
            'content_version': pack.contentVersion,
            'is_active': 1,
            'json_payload': jsonEncode(dialogue),
          },
        );
      }

      for (final rubric in pack.rubrics) {
        await _upsertByKey(
          txn,
          table: 'rubrics',
          keyColumn: 'rubric_id',
          keyValue: rubric['id'],
          values: {
            'rubric_id': rubric['id'],
            'pack_id': pack.packId,
            'kind': rubric['kind'],
            'content_version': pack.contentVersion,
            'is_active': 1,
            'json_payload': jsonEncode(rubric),
          },
        );
      }

      for (final event in pack.events) {
        await _upsertByKey(
          txn,
          table: 'events',
          keyColumn: 'event_id',
          keyValue: event['id'],
          values: {
            'event_id': event['id'],
            'pack_id': pack.packId,
            'event_type': event['eventType'],
            'content_version': pack.contentVersion,
            'is_active': 1,
            'json_payload': jsonEncode(event),
          },
        );
      }

      for (final achievement in pack.achievements) {
        await _upsertByKey(
          txn,
          table: 'achievements',
          keyColumn: 'achievement_id',
          keyValue: achievement['id'],
          values: {
            'achievement_id': achievement['id'],
            'pack_id': pack.packId,
            'title': achievement['title'],
            'description': achievement['description'],
            'rule_json': jsonEncode(achievement['rule']),
            'content_version': pack.contentVersion,
            'is_active': 1,
          },
        );
      }
    });

    return PackInstallResult(
      packId: pack.packId,
      installed: true,
      contentVersion: pack.contentVersion,
    );
  }

  Future<void> _validateOwnership(
    Database db,
    String table,
    String idColumn,
    String packId,
    List<Map<String, dynamic>> rows,
  ) async {
    for (final row in rows) {
      final id = row['id'];
      final existing = await db.query(
        table,
        columns: [idColumn, 'pack_id'],
        where: '$idColumn = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (existing.isEmpty) continue;
      final owner = existing.first['pack_id']?.toString();
      if (owner != null && owner.isNotEmpty && owner != packId) {
        throw FormatException(
          '$table id $id already belongs to content pack $owner.',
        );
      }
    }
  }

  Future<void> _upsertByKey(
    DatabaseExecutor executor, {
    required String table,
    required String keyColumn,
    required Object? keyValue,
    required Map<String, Object?> values,
  }) async {
    final updated = await executor.update(
      table,
      values,
      where: '$keyColumn = ?',
      whereArgs: [keyValue],
    );
    if (updated == 0) {
      await executor.insert(table, values);
    }
  }
}
