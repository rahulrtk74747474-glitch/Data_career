import 'dart:convert';

import 'package:dataquest_analyst_career/features/game/game_progress.dart';
import 'package:dataquest_analyst_career/models/backup_snapshot.dart';
import 'package:dataquest_analyst_career/services/cloud_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const config = CloudRuntimeConfig(
    supabaseUrl: 'https://project.supabase.co/',
    supabaseAnonKey: 'anon-key',
    weeklyCaseUrl: '',
  );
  const session = CloudSession(
    userId: '00000000-0000-0000-0000-000000000001',
    accessToken: 'token',
    email: 'analyst@example.com',
  );

  test('sync downloads remote, merges state and uploads merged snapshot', () async {
    final remote = _snapshot(
      xp: 2100,
      chapter: 4,
      completed: {'remote-task'},
      createdAt: DateTime.utc(2026, 10, 6, 10),
    );
    final local = _snapshot(
      xp: 900,
      chapter: 2,
      completed: {'local-task'},
      createdAt: DateTime.utc(2026, 10, 6, 11),
    );

    Map<String, dynamic>? uploaded;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode([
            {'payload': remote.toJson()},
          ]),
          200,
        );
      }
      if (request.method == 'POST') {
        uploaded = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('', 201);
      }
      return http.Response('unexpected', 500);
    });

    final service = SupabaseCloudService(
      config: config,
      client: client,
    );
    final result = await service.sync(
      session: session,
      local: local,
    );

    final mergedProgress = GameProgress.fromJson(result.snapshot.progress);
    expect(result.hadRemoteCopy, isTrue);
    expect(mergedProgress.xp, 2100);
    expect(
      mergedProgress.completedTaskIds,
      containsAll({'local-task', 'remote-task'}),
    );
    expect(uploaded, isNotNull);
    final payload = Map<String, dynamic>.from(
      uploaded!['payload'] as Map,
    );
    final uploadedProgress = GameProgress.fromJson(
      Map<String, dynamic>.from(payload['progress'] as Map),
    );
    expect(
      uploadedProgress.completedTaskIds,
      containsAll({'local-task', 'remote-task'}),
    );
    service.close();
  });
}

BackupSnapshot _snapshot({
  required int xp,
  required int chapter,
  required Set<String> completed,
  required DateTime createdAt,
}) {
  final progress = GameProgress(
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
    companyJourneyCompleted: chapter >= 4,
  );

  return BackupSnapshot(
    schemaVersion: BackupSnapshot.currentSchemaVersion,
    createdAt: createdAt,
    appVersion: '1.0.0+10',
    progress: progress.toJson(),
    reminderSettings: const {
      'dailyEnabled': false,
      'reviewEnabled': false,
      'dailyHour': 18,
      'dailyMinute': 0,
      'reviewHour': 19,
      'reviewMinute': 0,
    },
    tables: const {
      'skill_mastery': [],
      'placement_results': [],
      'boss_case_results': [],
      'task_performance': [],
      'interview_results': [],
      'evidence_attempts': [],
      'capstone_results': [],
    },
  );
}
