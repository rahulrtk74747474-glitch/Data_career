import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/flagship_attempt.dart';

class FlagshipAttemptRepository {
  const FlagshipAttemptRepository();

  static const _key = 'dataquest_flagship_attempts_v1';

  Future<Map<String, FlagshipAttempt>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final entry in decoded.entries)
        entry.key: FlagshipAttempt.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        ),
    };
  }

  Future<FlagshipAttempt> load(String workdayId) async {
    final all = await loadAll();
    return all[workdayId] ?? FlagshipAttempt(workdayId: workdayId);
  }

  Future<void> save(FlagshipAttempt attempt) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    all[attempt.workdayId] = attempt;
    await prefs.setString(
      _key,
      jsonEncode({
        for (final entry in all.entries) entry.key: entry.value.toJson(),
      }),
    );
  }
}
