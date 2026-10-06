import 'dart:convert';

import 'package:dataquest_analyst_career/services/cloud_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const config = CloudRuntimeConfig(
    supabaseUrl: 'https://project.supabase.co',
    supabaseAnonKey: 'public-anon-key',
    weeklyCaseUrl: '',
  );
  const session = CloudSession(
    userId: '00000000-0000-0000-0000-000000000001',
    accessToken: 'session-token',
    email: 'private@example.com',
  );

  test('leaderboard request excludes email and evidence details', () async {
    Map<String, dynamic>? payload;
    final client = MockClient((request) async {
      payload = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('', 201);
    });
    final service = SupabaseCloudService(
      config: config,
      client: client,
    );

    await service.publishLeaderboard(
      session: session,
      alias: 'Analyst_42',
      readinessScore: 88,
      graduated: true,
    );

    expect(payload, isNotNull);
    expect(
      payload!.keys.toSet(),
      {
        'user_id',
        'alias',
        'readiness_score',
        'graduated',
        'updated_at',
      },
    );
    expect(payload!.containsKey('email'), isFalse);
    expect(payload!.containsKey('evidence'), isFalse);
    expect(payload!['alias'], 'Analyst_42');
    service.close();
  });

  test('invalid alias is rejected before network publication', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return http.Response('', 201);
    });
    final service = SupabaseCloudService(
      config: config,
      client: client,
    );

    await expectLater(
      service.publishLeaderboard(
        session: session,
        alias: 'my real name!',
        readinessScore: 80,
        graduated: false,
      ),
      throwsA(isA<FormatException>()),
    );

    expect(calls, 0);
    service.close();
  });
}
