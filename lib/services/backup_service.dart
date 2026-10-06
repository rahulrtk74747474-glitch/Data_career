import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../features/game/game_progress.dart';
import '../models/backup_snapshot.dart';
import '../models/reminder_settings.dart';

class BackupExportResult {
  const BackupExportResult({
    required this.path,
    required this.bytes,
    required this.snapshot,
  });

  final String path;
  final int bytes;
  final BackupSnapshot snapshot;
}

class BackupService {
  const BackupService(this._database);

  static const appVersion = '1.1.0+11';
  static const _lastBackupKey = 'dataquest_last_backup_at_v1';

  static const stateTables = <String>[
    'skill_mastery',
    'placement_results',
    'boss_case_results',
    'task_performance',
    'interview_results',
    'evidence_attempts',
    'capstone_results',
  ];

  final AppDatabase _database;

  Future<BackupSnapshot> createSnapshot({
    required GameProgress progress,
    required ReminderSettings reminders,
  }) async {
    final db = await _database.database;
    final tables = <String, List<Map<String, dynamic>>>{};

    for (final table in stateTables) {
      final rows = await db.query(table);
      tables[table] = [
        for (final row in rows) Map<String, dynamic>.from(row),
      ];
    }

    return BackupSnapshot(
      schemaVersion: BackupSnapshot.currentSchemaVersion,
      createdAt: DateTime.now().toUtc(),
      appVersion: appVersion,
      progress: progress.toJson(),
      reminderSettings: reminders.toJson(),
      tables: tables,
    );
  }

  Future<BackupExportResult> exportToFile(BackupSnapshot snapshot) async {
    validate(snapshot);
    final base = await _database.storageDirectoryPath;
    final directory = Directory(p.join(base, 'backups'));
    await directory.create(recursive: true);
    final stamp = snapshot.createdAt
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File(
      p.join(directory.path, 'dataquest_backup_$stamp.json'),
    );
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(snapshot.toJson()),
      flush: true,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastBackupKey,
      snapshot.createdAt.toIso8601String(),
    );

    return BackupExportResult(
      path: file.path,
      bytes: await file.length(),
      snapshot: snapshot,
    );
  }

  BackupSnapshot decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Backup root must be an object.');
    }
    final snapshot = BackupSnapshot.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    validate(snapshot);
    return snapshot;
  }

  void validate(BackupSnapshot snapshot) {
    if (snapshot.schemaVersion > BackupSnapshot.currentSchemaVersion) {
      throw FormatException(
        'Backup schema ${snapshot.schemaVersion} is not supported.',
      );
    }

    final unknown = snapshot.tables.keys
        .where((table) => !stateTables.contains(table))
        .toList();
    if (unknown.isNotEmpty) {
      throw FormatException(
        'Backup contains unsupported tables: ${unknown.join(', ')}.',
      );
    }

    GameProgress.fromJson(snapshot.progress);
    ReminderSettings.fromJson(snapshot.reminderSettings);

    for (final table in stateTables) {
      final rows = snapshot.tables[table];
      if (rows == null) {
        throw FormatException('Backup is missing table $table.');
      }
      for (final row in rows) {
        if (row.keys.any((key) => key.trim().isEmpty)) {
          throw FormatException('Backup contains an invalid $table row.');
        }
      }
    }
  }

  Future<void> restoreDatabase(BackupSnapshot snapshot) async {
    validate(snapshot);
    final db = await _database.database;

    await db.transaction((txn) async {
      for (final table in stateTables) {
        await txn.delete(table);
      }

      for (final table in stateTables) {
        for (final row in snapshot.tables[table]!) {
          await txn.insert(
            table,
            Map<String, Object?>.from(row),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      }
    });
  }

  Future<void> restoreWithRollback({
    required BackupSnapshot snapshot,
    required GameProgress currentProgress,
    required ReminderSettings currentReminders,
    required Future<void> Function(
      GameProgress progress,
      ReminderSettings reminders,
    ) persistExternalState,
  }) async {
    validate(snapshot);
    final safety = await createSnapshot(
      progress: currentProgress,
      reminders: currentReminders,
    );

    try {
      await restoreDatabase(snapshot);
      await persistExternalState(
        GameProgress.fromJson(snapshot.progress),
        ReminderSettings.fromJson(snapshot.reminderSettings),
      );
      await recordRestoreAsBackupTime();
    } catch (_) {
      await restoreDatabase(safety);
      await persistExternalState(
        GameProgress.fromJson(safety.progress),
        ReminderSettings.fromJson(safety.reminderSettings),
      );
      rethrow;
    }
  }

  Future<DateTime?> lastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastBackupKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> recordRestoreAsBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastBackupKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }
}
