import '../features/game/game_progress.dart';
import '../models/backup_snapshot.dart';

class SnapshotMergeService {
  const SnapshotMergeService._();

  static BackupSnapshot merge(
    BackupSnapshot local,
    BackupSnapshot remote,
  ) {
    final localProgress = GameProgress.fromJson(local.progress);
    final remoteProgress = GameProgress.fromJson(remote.progress);
    final dominant = _compareProgress(
              localProgress,
              remoteProgress,
              local.createdAt,
              remote.createdAt,
            ) >=
            0
        ? local
        : remote;
    final dominantProgress = GameProgress.fromJson(dominant.progress);

    final mergedProgress = dominantProgress.copyWith(
      xp: localProgress.xp > remoteProgress.xp
          ? localProgress.xp
          : remoteProgress.xp,
      streak: localProgress.streak > remoteProgress.streak
          ? localProgress.streak
          : remoteProgress.streak,
      completedTaskIds: {
        ...localProgress.completedTaskIds,
        ...remoteProgress.completedTaskIds,
      },
      careerLevel: localProgress.careerLevel > remoteProgress.careerLevel
          ? localProgress.careerLevel
          : remoteProgress.careerLevel,
      dailyStreak: localProgress.dailyStreak > remoteProgress.dailyStreak
          ? localProgress.dailyStreak
          : remoteProgress.dailyStreak,
      lastDailyDate: _laterDateKey(
        localProgress.lastDailyDate,
        remoteProgress.lastDailyDate,
      ),
      completedDailyDates: {
        ...localProgress.completedDailyDates,
        ...remoteProgress.completedDailyDates,
      },
      companyChapter:
          localProgress.resolvedCompanyChapter >
                  remoteProgress.resolvedCompanyChapter
              ? localProgress.resolvedCompanyChapter
              : remoteProgress.resolvedCompanyChapter,
      companyJourneyCompleted:
          localProgress.companyJourneyCompleted ||
              remoteProgress.companyJourneyCompleted,
    );

    return BackupSnapshot(
      schemaVersion: BackupSnapshot.currentSchemaVersion,
      createdAt: DateTime.now().toUtc(),
      appVersion: dominant.appVersion,
      progress: mergedProgress.toJson(),
      reminderSettings: local.reminderSettings,
      tables: {
        'skill_mastery': _mergeKeyed(
          local.tables['skill_mastery'] ?? const [],
          remote.tables['skill_mastery'] ?? const [],
          'skill_key',
          _preferAttemptsThenScore,
        ),
        'placement_results': _mergeKeyed(
          local.tables['placement_results'] ?? const [],
          remote.tables['placement_results'] ?? const [],
          'id',
          _preferDateThenScore,
        ),
        'boss_case_results': _mergeKeyed(
          local.tables['boss_case_results'] ?? const [],
          remote.tables['boss_case_results'] ?? const [],
          'case_id',
          _preferDateThenScore,
        ),
        'task_performance': _mergeKeyed(
          local.tables['task_performance'] ?? const [],
          remote.tables['task_performance'] ?? const [],
          'task_id',
          _preferAttemptsThenScore,
        ),
        'interview_results': _mergeKeyed(
          local.tables['interview_results'] ?? const [],
          remote.tables['interview_results'] ?? const [],
          'round_key',
          _preferAttemptsThenScore,
        ),
        'evidence_attempts': _mergeEvidence(
          local.tables['evidence_attempts'] ?? const [],
          remote.tables['evidence_attempts'] ?? const [],
        ),
        'capstone_results': _mergeKeyed(
          local.tables['capstone_results'] ?? const [],
          remote.tables['capstone_results'] ?? const [],
          'capstone_id',
          _preferDateThenScore,
        ),
      },
    );
  }

  static int _compareProgress(
    GameProgress a,
    GameProgress b,
    DateTime aCreated,
    DateTime bCreated,
  ) {
    final aRank = [
      a.companyJourneyCompleted ? 1 : 0,
      a.resolvedCompanyChapter,
      a.careerLevel,
      a.completedTaskIds.length,
      a.xp,
    ];
    final bRank = [
      b.companyJourneyCompleted ? 1 : 0,
      b.resolvedCompanyChapter,
      b.careerLevel,
      b.completedTaskIds.length,
      b.xp,
    ];
    for (var index = 0; index < aRank.length; index++) {
      final comparison = aRank[index].compareTo(bRank[index]);
      if (comparison != 0) return comparison;
    }
    return aCreated.compareTo(bCreated);
  }

  static String? _laterDateKey(String? a, String? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.compareTo(b) >= 0 ? a : b;
  }

  static List<Map<String, dynamic>> _mergeKeyed(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> remote,
    String key,
    Map<String, dynamic> Function(
      Map<String, dynamic>,
      Map<String, dynamic>,
    ) choose,
  ) {
    final merged = <String, Map<String, dynamic>>{};
    for (final row in [...remote, ...local]) {
      final rowKey = row[key]?.toString();
      if (rowKey == null) continue;
      final existing = merged[rowKey];
      merged[rowKey] = existing == null ? row : choose(existing, row);
    }
    final result = merged.values.toList()
      ..sort((a, b) => a[key].toString().compareTo(b[key].toString()));
    return result;
  }

  static Map<String, dynamic> _preferAttemptsThenScore(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aAttempts = _number(a['attempts'] ?? a['correct_count']);
    final bAttempts = _number(b['attempts'] ?? b['correct_count']);
    if (aAttempts != bAttempts) {
      return aAttempts > bAttempts ? a : b;
    }
    final aScore = _score(a);
    final bScore = _score(b);
    if (aScore != bScore) return aScore > bScore ? a : b;
    return _preferDateThenScore(a, b);
  }

  static Map<String, dynamic> _preferDateThenScore(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final aDate = _date(a);
    final bDate = _date(b);
    if (aDate != null && bDate != null && aDate != bDate) {
      return aDate.isAfter(bDate) ? a : b;
    }
    final aScore = _score(a);
    final bScore = _score(b);
    if (aScore != bScore) return aScore > bScore ? a : b;
    final aText = a.toString();
    final bText = b.toString();
    return aText.compareTo(bText) >= 0 ? a : b;
  }

  static double _number(Object? value) => (value as num?)?.toDouble() ?? 0;

  static double _score(Map<String, dynamic> row) {
    for (final key in const [
      'total_score',
      'best_score',
      'mastery',
      'latest_score',
    ]) {
      if (row[key] is num) return (row[key] as num).toDouble();
    }
    return 0;
  }

  static DateTime? _date(Map<String, dynamic> row) {
    for (final key in const [
      'completed_at',
      'last_completed_at',
      'next_review_at',
    ]) {
      final value = row[key];
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> _mergeEvidence(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> remote,
  ) {
    final unique = <String, Map<String, dynamic>>{};
    for (final row in [...remote, ...local]) {
      final fingerprint = [
        row['source_type'],
        row['source_id'],
        row['title'],
        row['skill_key'],
        row['score'],
        row['mode'],
        row['company_key'],
        row['completed_at'],
      ].join('|');
      unique[fingerprint] = Map<String, dynamic>.from(row)
        ..remove('attempt_id');
    }

    final rows = unique.entries.toList()
      ..sort((a, b) {
        final ad = DateTime.tryParse(
          a.value['completed_at']?.toString() ?? '',
        );
        final bd = DateTime.tryParse(
          b.value['completed_at']?.toString() ?? '',
        );
        final byDate = (ad ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(bd ?? DateTime.fromMillisecondsSinceEpoch(0));
        return byDate != 0 ? byDate : a.key.compareTo(b.key);
      });

    return [
      for (var index = 0; index < rows.length; index++)
        {
          'attempt_id': index + 1,
          ...rows[index].value,
        },
    ];
  }
}
