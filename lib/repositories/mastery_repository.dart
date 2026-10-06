import 'package:sqflite/sqflite.dart';

import '../data/app_database.dart';
import '../models/skill_mastery.dart';

class MasteryRepository {
  const MasteryRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<SkillMastery>> loadSkills() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'skill_mastery',
      orderBy: 'skill_key',
    );
    return rows.map(SkillMastery.fromMap).toList();
  }

  Future<bool> hasCompletedPlacement() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'placement_results',
      columns: ['id'],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> applyPlacement(Map<String, int> scores) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      for (final entry in scores.entries) {
        final score = entry.value.clamp(0, 100).toInt();
        await txn.update(
          'skill_mastery',
          {
            'mastery': score.toDouble(),
            'attempts': 1,
            'correct_count': score >= 60 ? 1 : 0,
            'next_review_at': _nextReview(score).toIso8601String(),
          },
          where: 'skill_key = ?',
          whereArgs: [entry.key],
        );
      }

      final total = scores.isEmpty
          ? 0
          : (scores.values.reduce((a, b) => a + b) / scores.length).round();

      await txn.insert(
        'placement_results',
        {
          'id': 1,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
          'total_score': total,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> recordAttempt(String skillKey, int score) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'skill_mastery',
        where: 'skill_key = ?',
        whereArgs: [skillKey],
        limit: 1,
      );
      if (rows.isEmpty) return;

      final row = rows.first;
      final attempts = (row['attempts'] as num).toInt();
      final currentMastery = (row['mastery'] as num).toDouble();
      final normalizedScore = score.clamp(0, 100).toDouble();
      final updatedMastery = attempts == 0
          ? normalizedScore
          : ((currentMastery * 0.70) + (normalizedScore * 0.30))
              .clamp(0, 100)
              .toDouble();

      await txn.update(
        'skill_mastery',
        {
          'mastery': updatedMastery,
          'attempts': attempts + 1,
          'correct_count': (row['correct_count'] as num).toInt() +
              (score >= 70 ? 1 : 0),
          'next_review_at': _nextReview(score).toIso8601String(),
        },
        where: 'skill_key = ?',
        whereArgs: [skillKey],
      );
    });
  }

  Future<void> resetAll() async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await txn.update(
        'skill_mastery',
        {
          'mastery': 0.0,
          'attempts': 0,
          'correct_count': 0,
          'next_review_at': null,
        },
      );
      await txn.delete('placement_results');
    });
  }

  static DateTime _nextReview(int score) {
    final days = score < 60
        ? 1
        : score < 80
            ? 3
            : 7;
    return DateTime.now().toUtc().add(Duration(days: days));
  }
}
