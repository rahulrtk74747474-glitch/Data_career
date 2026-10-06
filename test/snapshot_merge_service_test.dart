import 'package:dataquest_analyst_career/features/game/game_progress.dart';
import 'package:dataquest_analyst_career/models/backup_snapshot.dart';
import 'package:dataquest_analyst_career/services/snapshot_merge_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merge unions career completion and deduplicates immutable evidence', () {
    final local = _snapshot(
      createdAt: DateTime.utc(2026, 10, 6, 10),
      progress: _progress(
        xp: 900,
        chapter: 2,
        completed: {'local-task'},
        journey: false,
      ),
      evidence: [
        _evidence(1, 'shared', 80, '2026-10-05T10:00:00Z'),
        _evidence(2, 'local', 85, '2026-10-06T09:00:00Z'),
      ],
      reminders: const {'dailyEnabled': true},
    );
    final remote = _snapshot(
      createdAt: DateTime.utc(2026, 10, 6, 11),
      progress: _progress(
        xp: 2200,
        chapter: 4,
        completed: {'remote-task'},
        journey: true,
      ),
      evidence: [
        _evidence(20, 'shared', 80, '2026-10-05T10:00:00Z'),
        _evidence(21, 'remote', 90, '2026-10-06T10:00:00Z'),
      ],
      reminders: const {'dailyEnabled': false},
    );

    final merged = SnapshotMergeService.merge(local, remote);
    final progress = GameProgress.fromJson(merged.progress);
    final evidence = merged.tables['evidence_attempts']!;

    expect(progress.xp, 2200);
    expect(progress.resolvedCompanyChapter, 4);
    expect(progress.companyJourneyCompleted, isTrue);
    expect(progress.completedTaskIds, containsAll({'local-task', 'remote-task'}));
    expect(evidence, hasLength(3));
    expect(
      evidence.map((row) => row['source_id']).toSet(),
      {'shared', 'local', 'remote'},
    );
    expect(
      evidence.map((row) => row['attempt_id']).toList(),
      [1, 2, 3],
    );
    expect(merged.reminderSettings['dailyEnabled'], isTrue);
  });

  test('per-skill merge prefers greater attempt evidence before score', () {
    final local = _snapshot(
      createdAt: DateTime.utc(2026, 10, 6),
      progress: _progress(
        xp: 500,
        chapter: 1,
        completed: const {},
        journey: false,
      ),
      evidence: const [],
      reminders: const {},
      skillRows: const [
        {
          'skill_key': 'sql',
          'mastery': 95.0,
          'attempts': 2,
          'correct_count': 2,
          'next_review_at': null,
        },
      ],
    );
    final remote = _snapshot(
      createdAt: DateTime.utc(2026, 10, 6),
      progress: _progress(
        xp: 500,
        chapter: 1,
        completed: const {},
        journey: false,
      ),
      evidence: const [],
      reminders: const {},
      skillRows: const [
        {
          'skill_key': 'sql',
          'mastery': 80.0,
          'attempts': 5,
          'correct_count': 4,
          'next_review_at': null,
        },
      ],
    );

    final merged = SnapshotMergeService.merge(local, remote);
    final sql = merged.tables['skill_mastery']!.single;

    expect(sql['attempts'], 5);
    expect(sql['mastery'], 80.0);
  });
}

BackupSnapshot _snapshot({
  required DateTime createdAt,
  required GameProgress progress,
  required List<Map<String, dynamic>> evidence,
  required Map<String, dynamic> reminders,
  List<Map<String, dynamic>> skillRows = const [],
}) {
  return BackupSnapshot(
    schemaVersion: BackupSnapshot.currentSchemaVersion,
    createdAt: createdAt,
    appVersion: '1.0.0+10',
    progress: progress.toJson(),
    reminderSettings: reminders,
    tables: {
      'skill_mastery': skillRows,
      'placement_results': const [],
      'boss_case_results': const [],
      'task_performance': const [],
      'interview_results': const [],
      'evidence_attempts': evidence,
      'capstone_results': const [],
    },
  );
}

GameProgress _progress({
  required int xp,
  required int chapter,
  required Set<String> completed,
  required bool journey,
}) {
  return GameProgress(
    xp: xp,
    streak: 0,
    completedTaskIds: completed,
    revenueIndex: 100,
    churnRate: 8,
    costIndex: 100,
    satisfaction: 70,
    careerLevel: chapter >= 4 ? 5 : chapter + 1,
    dailyStreak: 0,
    lastDailyDate: null,
    completedDailyDates: const {},
    companyChapter: chapter,
    companyJourneyCompleted: journey,
  );
}

Map<String, dynamic> _evidence(
  int id,
  String sourceId,
  int score,
  String completedAt,
) {
  return {
    'attempt_id': id,
    'source_type': 'task',
    'source_id': sourceId,
    'title': sourceId,
    'skill_key': 'sql',
    'score': score,
    'mode': 'career',
    'company_key': 'ecommerce',
    'completed_at': completedAt,
  };
}
