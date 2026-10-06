import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/backup_snapshot.dart';
import 'snapshot_merge_service.dart';

class CloudRuntimeConfig {
  const CloudRuntimeConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.weeklyCaseUrl,
  });

  factory CloudRuntimeConfig.fromEnvironment() {
    return const CloudRuntimeConfig(
      supabaseUrl: String.fromEnvironment('DATAQUEST_SUPABASE_URL'),
      supabaseAnonKey:
          String.fromEnvironment('DATAQUEST_SUPABASE_ANON_KEY'),
      weeklyCaseUrl: String.fromEnvironment('DATAQUEST_WEEKLY_CASE_URL'),
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String weeklyCaseUrl;

  bool get cloudConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  bool get weeklyCasesConfigured => weeklyCaseUrl.trim().isNotEmpty;
}

class CloudSession {
  const CloudSession({
    required this.userId,
    required this.accessToken,
    required this.email,
  });

  final String userId;
  final String accessToken;
  final String email;
}

class CloudSignUpResult {
  const CloudSignUpResult({
    required this.message,
    this.session,
  });

  final String message;
  final CloudSession? session;
}

class CloudSyncResult {
  const CloudSyncResult({
    required this.snapshot,
    required this.hadRemoteCopy,
  });

  final BackupSnapshot snapshot;
  final bool hadRemoteCopy;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.alias,
    required this.readinessScore,
    required this.graduated,
    required this.updatedAt,
  });

  final String alias;
  final int readinessScore;
  final bool graduated;
  final DateTime updatedAt;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      alias: json['alias'] as String,
      readinessScore: (json['readiness_score'] as num).toInt(),
      graduated: (json['graduated'] as bool?) ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

abstract interface class CloudSyncGateway {
  CloudRuntimeConfig get config;

  Future<CloudSession> signIn({
    required String email,
    required String password,
  });

  Future<CloudSignUpResult> signUp({
    required String email,
    required String password,
  });

  Future<BackupSnapshot?> loadBackup(CloudSession session);

  Future<void> saveBackup(
    CloudSession session,
    BackupSnapshot snapshot,
  );

  Future<CloudSyncResult> sync({
    required CloudSession session,
    required BackupSnapshot local,
  });

  Future<void> publishLeaderboard({
    required CloudSession session,
    required String alias,
    required int readinessScore,
    required bool graduated,
  });

  Future<List<LeaderboardEntry>> loadLeaderboard({
    required CloudSession session,
    int limit = 25,
  });

  void close();
}

class SupabaseCloudService implements CloudSyncGateway {
  SupabaseCloudService({
    CloudRuntimeConfig? config,
    http.Client? client,
  })  : config = config ?? CloudRuntimeConfig.fromEnvironment(),
        _client = client ?? http.Client();

  final CloudRuntimeConfig config;
  final http.Client _client;

  Future<CloudSession> signIn({
    required String email,
    required String password,
  }) async {
    _requireCloud();
    final response = await _client.post(
      Uri.parse(
        '${_baseUrl()}/auth/v1/token?grant_type=password',
      ),
      headers: {
        'apikey': config.supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_message(response, 'Cloud sign-in failed.'));
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final user = decoded['user'] as Map<String, dynamic>?;
    final token = decoded['access_token'] as String?;
    final userId = user?['id'] as String?;
    if (token == null || userId == null) {
      throw StateError('Cloud sign-in response is incomplete.');
    }

    return CloudSession(
      userId: userId,
      accessToken: token,
      email: email.trim(),
    );
  }

  Future<CloudSignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    _requireCloud();
    final response = await _client.post(
      Uri.parse('${_baseUrl()}/auth/v1/signup'),
      headers: {
        'apikey': config.supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_message(response, 'Cloud sign-up failed.'));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final user = decoded['user'] as Map<String, dynamic>?;
    final token = decoded['access_token'] as String?;
    final userId = user?['id'] as String?;
    if (token != null && userId != null) {
      return CloudSignUpResult(
        message: 'Cloud account created and signed in for this session.',
        session: CloudSession(
          userId: userId,
          accessToken: token,
          email: email.trim(),
        ),
      );
    }

    return const CloudSignUpResult(
      message:
          'Account created. If email confirmation is enabled, confirm the email and then sign in.',
    );
  }

  Future<BackupSnapshot?> loadBackup(CloudSession session) async {
    _requireCloud();
    final uri = Uri.parse(
      '${_baseUrl()}/rest/v1/dataquest_saves',
    ).replace(
      queryParameters: {
        'user_id': 'eq.${session.userId}',
        'select': 'payload',
        'limit': '1',
      },
    );
    final response = await _client.get(
      uri,
      headers: _authHeaders(session),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_message(response, 'Cloud backup download failed.'));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) return null;
    final row = Map<String, dynamic>.from(decoded.first as Map);
    final payload = row['payload'];
    if (payload is! Map) {
      throw const FormatException('Cloud backup payload is invalid.');
    }
    return BackupSnapshot.fromJson(
      Map<String, dynamic>.from(payload),
    );
  }

  Future<void> saveBackup(
    CloudSession session,
    BackupSnapshot snapshot,
  ) async {
    _requireCloud();
    final response = await _client.post(
      Uri.parse('${_baseUrl()}/rest/v1/dataquest_saves'),
      headers: {
        ..._authHeaders(session),
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates,return=minimal',
      },
      body: jsonEncode({
        'user_id': session.userId,
        'payload': snapshot.toJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_message(response, 'Cloud backup upload failed.'));
    }
  }

  Future<CloudSyncResult> sync({
    required CloudSession session,
    required BackupSnapshot local,
  }) async {
    final remote = await loadBackup(session);
    final merged =
        remote == null ? local : SnapshotMergeService.merge(local, remote);
    await saveBackup(session, merged);
    return CloudSyncResult(
      snapshot: merged,
      hadRemoteCopy: remote != null,
    );
  }

  Future<void> publishLeaderboard({
    required CloudSession session,
    required String alias,
    required int readinessScore,
    required bool graduated,
  }) async {
    _requireCloud();
    final normalizedAlias = alias.trim();
    if (!RegExp(r'^[A-Za-z0-9_]{3,20}$').hasMatch(normalizedAlias)) {
      throw const FormatException(
        'Alias must be 3–20 letters, numbers or underscores.',
      );
    }

    final response = await _client.post(
      Uri.parse('${_baseUrl()}/rest/v1/dataquest_leaderboard'),
      headers: {
        ..._authHeaders(session),
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates,return=minimal',
      },
      body: jsonEncode({
        'user_id': session.userId,
        'alias': normalizedAlias,
        'readiness_score': readinessScore.clamp(0, 100),
        'graduated': graduated,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        _message(response, 'Leaderboard publish failed.'),
      );
    }
  }

  Future<List<LeaderboardEntry>> loadLeaderboard({
    required CloudSession session,
    int limit = 25,
  }) async {
    _requireCloud();
    final uri = Uri.parse(
      '${_baseUrl()}/rest/v1/dataquest_leaderboard',
    ).replace(
      queryParameters: {
        'select': 'alias,readiness_score,graduated,updated_at',
        'order': 'readiness_score.desc,updated_at.asc',
        'limit': limit.clamp(1, 100).toString(),
      },
    );
    final response = await _client.get(
      uri,
      headers: _authHeaders(session),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        _message(response, 'Leaderboard download failed.'),
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('Leaderboard response is invalid.');
    }
    return [
      for (final row in decoded)
        LeaderboardEntry.fromJson(
          Map<String, dynamic>.from(row as Map),
        ),
    ];
  }

  void close() => _client.close();

  Map<String, String> _authHeaders(CloudSession session) => {
        'apikey': config.supabaseAnonKey,
        'Authorization': 'Bearer ${session.accessToken}',
      };

  String _baseUrl() =>
      config.supabaseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  void _requireCloud() {
    if (!config.cloudConfigured) {
      throw StateError(
        'Cloud sync is not configured in this build.',
      );
    }
  }

  String _message(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final message =
            decoded['msg'] ?? decoded['message'] ?? decoded['error_description'];
        if (message != null) return message.toString();
      }
    } catch (_) {
      // Use the status-based fallback below.
    }
    return '$fallback HTTP ${response.statusCode}.';
  }
}
