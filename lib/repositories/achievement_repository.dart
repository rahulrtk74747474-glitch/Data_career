import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../models/achievement_badge.dart';

class AchievementRepository {
  const AchievementRepository(this._database);

  final AppDatabase _database;

  Future<void> sync(List<AchievementBadge> badges) async {
    final db = await _database.database;
    final now = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      for (final badge in badges) {
        await txn.insert(
          'achievements',
          {
            'achievement_id': badge.id,
            'title': badge.title,
            'description': badge.description,
            'rule_json': jsonEncode({
              'type': 'computed_v11',
            }),
            'content_version': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (badge.unlocked) {
          await txn.insert(
            'user_achievements',
            {
              'user_id': 'local-player',
              'achievement_id': badge.id,
              'unlocked_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });
  }

  Future<Set<String>> loadUnlocked() async {
    final db = await _database.database;
    final rows = await db.query(
      'user_achievements',
      columns: ['achievement_id'],
      where: 'user_id = ?',
      whereArgs: ['local-player'],
    );
    return rows
        .map((row) => row['achievement_id'] as String)
        .toSet();
  }
}
