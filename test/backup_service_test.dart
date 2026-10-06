import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/features/game/game_progress.dart';
import 'package:dataquest_analyst_career/models/backup_snapshot.dart';
import 'package:dataquest_analyst_career/models/reminder_settings.dart';
import 'package:dataquest_analyst_career/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late BackupService service;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
    service = BackupService(database);
  });

  tearDown(() => database.close());

  test('portable backup restores database progress and reminders', () async {
    final db = await database.database;
    await db.update(
      'skill_mastery',
      {
        'mastery': 88.0,
        'attempts': 4,
        'correct_count': 3,
      },
      where: 'skill_key = ?',
      whereArgs: ['sql'],
    );

    final sourceProgress = _progress(xp: 777, completed: {'task-a'});
    const sourceReminders = ReminderSettings(
      dailyEnabled: true,
      reviewEnabled: false,
      dailyHour: 18,
      dailyMinute: 30,
      reviewHour: 19,
      reviewMinute: 0,
    );
    final snapshot = await service.createSnapshot(
      progress: sourceProgress,
      reminders: sourceReminders,
    );

    await db.update(
      'skill_mastery',
      {
        'mastery': 5.0,
        'attempts': 1,
        'correct_count': 0,
      },
      where: 'skill_key = ?',
      whereArgs: ['sql'],
    );

    var restoredProgress = GameProgress.initial();
    var restoredReminders = ReminderSettings.defaults();
    await service.restoreWithRollback(
      snapshot: snapshot,
      currentProgress: GameProgress.initial(),
      currentReminders: ReminderSettings.defaults(),
      persistExternalState: (progress, reminders) async {
        restoredProgress = progress;
        restoredReminders = reminders;
      },
    );

    final rows = await db.query(
      'skill_mastery',
      where: 'skill_key = ?',
      whereArgs: ['sql'],
    );
    expect((rows.single['mastery'] as num).toDouble(), 88);
    expect(restoredProgress.xp, 777);
    expect(restoredProgress.completedTaskIds, contains('task-a'));
    expect(restoredReminders.dailyEnabled, isTrue);
    expect(restoredReminders.dailyMinute, 30);
  });

  test('failed table import rolls database and external state back', () async {
    final db = await database.database;
    await db.update(
      'skill_mastery',
      {
        'mastery': 71.0,
        'attempts': 3,
        'correct_count': 2,
      },
      where: 'skill_key = ?',
      whereArgs: ['sql'],
    );

    final currentProgress = _progress(xp: 500, completed: {'safe'});
    final currentReminders = ReminderSettings.defaults();
    final valid = await service.createSnapshot(
      progress: _progress(xp: 999, completed: {'incoming'}),
      reminders: currentReminders,
    );
    final duplicateRows = [
      ...valid.tables['skill_mastery']!,
      Map<String, dynamic>.from(valid.tables['skill_mastery']!.first),
    ];
    final broken = BackupSnapshot(
      schemaVersion: valid.schemaVersion,
      createdAt: valid.createdAt,
      appVersion: valid.appVersion,
      progress: valid.progress,
      reminderSettings: valid.reminderSettings,
      tables: {
        ...valid.tables,
        'skill_mastery': duplicateRows,
      },
    );

    var externalProgress = currentProgress;
    var externalReminders = currentReminders;

    await expectLater(
      service.restoreWithRollback(
        snapshot: broken,
        currentProgress: currentProgress,
        currentReminders: currentReminders,
        persistExternalState: (progress, reminders) async {
          externalProgress = progress;
          externalReminders = reminders;
        },
      ),
      throwsA(anything),
    );

    final rows = await db.query(
      'skill_mastery',
      where: 'skill_key = ?',
      whereArgs: ['sql'],
    );
    expect((rows.single['mastery'] as num).toDouble(), 71);
    expect(externalProgress.xp, 500);
    expect(externalProgress.completedTaskIds, contains('safe'));
    expect(externalReminders.dailyEnabled, isFalse);
  });

  test('newer backup schema is rejected before restore', () {
    final json = {
      'format': 'dataquest-backup',
      'schemaVersion': BackupSnapshot.currentSchemaVersion + 1,
      'createdAt': DateTime.utc(2026, 10, 6).toIso8601String(),
      'appVersion': 'future',
      'progress': <String, dynamic>{},
      'reminderSettings': <String, dynamic>{},
      'tables': <String, dynamic>{},
    };

    expect(
      () => BackupSnapshot.fromJson(json),
      throwsA(isA<FormatException>()),
    );
  });
}

GameProgress _progress({
  required int xp,
  required Set<String> completed,
}) {
  return GameProgress(
    xp: xp,
    streak: 1,
    completedTaskIds: completed,
    revenueIndex: 101,
    churnRate: 7.5,
    costIndex: 99,
    satisfaction: 72,
    careerLevel: 2,
    dailyStreak: 2,
    lastDailyDate: '2026-10-06',
    completedDailyDates: const {'2026-10-06'},
    companyChapter: 1,
  );
}
