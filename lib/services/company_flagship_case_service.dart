import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import 'sql_result_grader.dart';

/// Four additional fully seeded, reproducible SQL flagship datasets.
///
/// Every case is a versioned source-event fixture; the clean view resolves
/// latest-ingestion changes and duplicate events by business_id and case_id.
class CompanyFlagshipCaseService {
  const CompanyFlagshipCaseService(this._database);
  final AppDatabase _database;

  static const assetPath = 'assets/content/flagship_company_cases_v1.json';
  static const validCases = ['saas', 'bank', 'hospital', 'logistics'];
  static const table = 'dq_case_events';
  static const view = 'dq_case_latest';
  static const schema = <String>[
    'CREATE TABLE IF NOT EXISTS dq_case_events ('
        'case_id TEXT NOT NULL, event_id TEXT PRIMARY KEY, '
        'business_id TEXT NOT NULL, group_name TEXT NOT NULL, '
        'status TEXT NOT NULL, metric_value REAL NOT NULL, '
        'denominator_value REAL NOT NULL, ingested_at TEXT NOT NULL)',
    'CREATE TABLE IF NOT EXISTS dq_case_versions ('
        'case_id TEXT PRIMARY KEY, version INTEGER NOT NULL)',
    '''CREATE VIEW IF NOT EXISTS dq_case_latest AS
       SELECT case_id, event_id, business_id, group_name, status,
              metric_value, denominator_value, ingested_at
       FROM (
         SELECT *, ROW_NUMBER() OVER (
           PARTITION BY case_id, business_id
           ORDER BY ingested_at DESC, event_id DESC
         ) AS event_rank
         FROM dq_case_events
       ) WHERE event_rank = 1''',
  ];

  static String get portableSchema => schema.join(';\n\n') + ';\n';

  Future<Map<String, dynamic>> _pack() async =>
      Map<String, dynamic>.from(
        jsonDecode(await rootBundle.loadString(assetPath)) as Map,
      );

  Future<Map<String, dynamic>> definition(String key) async {
    if (!validCases.contains(key)) {
      throw ArgumentError.value(key, 'key', 'Unknown flagship case.');
    }
    final pack = await _pack();
    if (pack['schemaVersion'] != 1) {
      throw StateError('Unsupported company case pack.');
    }
    final cases = pack['cases'] as List;
    return Map<String, dynamic>.from(
      cases.firstWhere((item) => (item as Map)['key'] == key) as Map,
    );
  }

  Future<void> ensureReady() async {
    final pack = await _pack();
    if (pack['schemaVersion'] != 1) throw StateError('Unsupported pack.');
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final statement in schema) {
        await txn.execute(statement);
      }
      for (final raw in (pack['cases'] as List)) {
        final item = Map<String, dynamic>.from(raw as Map);
        final key = item['key'] as String;
        if (!validCases.contains(key)) throw StateError('Unknown case key.');
        final existing = await txn.query('dq_case_versions',
            where: 'case_id = ?', whereArgs: [key], limit: 1);
        if (existing.isNotEmpty &&
            (existing.first['version'] as num).toInt() == 1) {
          continue;
        }
        await txn.delete(table, where: 'case_id = ?', whereArgs: [key]);
        for (final event in (item['events'] as List)) {
          await txn.insert(
            table, Map<String, Object?>.from(event as Map),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
        await txn.insert('dq_case_versions',
            {'case_id': key, 'version': 1},
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, Object?>>> rows(String key) async {
    await ensureReady();
    final db = await _database.database;
    return db.query(table, where: 'case_id = ?', whereArgs: [key],
        orderBy: 'event_id');
  }

  Future<List<Map<String, Object?>>> cleanedRows(String key) async {
    await ensureReady();
    final db = await _database.database;
    return db.query(view, where: 'case_id = ?', whereArgs: [key],
        orderBy: 'business_id');
  }

  Future<List<Map<String, Object?>>> referenceRows(String key) async {
    final item = await definition(key);
    await ensureReady();
    return (await (await _database.database)
        .rawQuery(item['referenceQuery'] as String));
  }

  static String? integrityWarning(String query, String key) {
    final sql = query.toLowerCase()
        .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), ' ')
        .replaceAll(RegExp(r'--[^\n\r]*'), ' ')
        .replaceAll(RegExp(r"'(?:''|[^'])*'"), "''");
    if (!RegExp(r'\b(?:from|join)\s+(?:main\.)?dq_case_latest\b')
        .hasMatch(sql)) {
      return 'Use dq_case_latest as the SQL FROM/JOIN source; '
          'raw event rows contain duplicates and updates.';
    }
    if (!query.toLowerCase().contains("case_id")) {
      return 'Filter on case_id for the requested company case.';
    }
    if (query.contains('--') || query.contains('/*')) {
      return 'Remove comments from the assessed query.';
    }
    return null;
  }

  Future<SqlResultGrade> verifyChangedData(String key, String query) async {
    final warning = integrityWarning(query, key);
    if (warning != null) {
      return SqlResultGrade(isCorrect: false, feedback: warning);
    }
    final item = await definition(key);
    await ensureReady();
    final db = await _database.database;
    SqlResultGrade? grade;
    try {
      await db.transaction((txn) async {
        final changed = await txn.rawUpdate(
          'UPDATE dq_case_events '
          'SET metric_value = metric_value + 317, '
          'denominator_value = denominator_value + 7 '
          'WHERE case_id = ? AND event_id = ?',
          [key, item['holdoutEventId']],
        );
        if (changed != 1) throw StateError('Holdout fixture is missing.');
        final actual = await txn.rawQuery(query);
        final expected = await txn.rawQuery(item['referenceQuery'] as String);
        grade = actual.length > 100
            ? const SqlResultGrade(
                isCorrect: false, feedback: 'Too many rows for assessment.',
              )
            : SqlResultGrader.grade(
                actualRows: actual,
                expectedRows: [
                  for (final row in expected)
                    Map<String, dynamic>.from(row),
                ],
              );
        throw const _RollbackHoldout();
      });
    } on _RollbackHoldout {
      return grade!;
    }
  }
}

class _RollbackHoldout {
  const _RollbackHoldout();
}
