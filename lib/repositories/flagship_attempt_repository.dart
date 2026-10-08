import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/flagship_attempt.dart';

class FlagshipAttemptRepository {
  const FlagshipAttemptRepository();

  static const _key = 'dataquest_flagship_attempts_v1';
  // Keep concurrent autosave/completion writes from overwriting each other.
  static Future<void> _saveQueue = Future<void>.value();

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

  Future<void> save(FlagshipAttempt attempt) {
    final work = _saveQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final all = await loadAll();
      all[attempt.workdayId] = attempt;
      final ok = await prefs.setString(
        _key,
        jsonEncode({
          for (final entry in all.entries) entry.key: entry.value.toJson(),
        }),
      );
      if (!ok) throw StateError('The local workday draft was not saved.');
    });
    _saveQueue = work.then<void>(
      (_) {},
      onError: (Object error, StackTrace trace) {},
    );
    return work;
  }}
