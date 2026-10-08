import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LearningHealthReport {
  const LearningHealthReport({
    required this.firstOpen,
    required this.activeDates,
    required this.appOpens,
    required this.workdayStarts,
    required this.stageCompletions,
    required this.workdayCompletions,
    required this.firstFlagshipCompletedAt,
    required this.feedbackCount,
    required this.latestFeedback,
  });

  final DateTime? firstOpen;
  final List<String> activeDates;
  final int appOpens;
  final int workdayStarts;
  /// Counts of completed steps, used to find where learners abandon workdays.
  final Map<String, int> stageCompletions;
  final int workdayCompletions;
  final DateTime? firstFlagshipCompletedAt;
  final int feedbackCount;
  final Map<String, dynamic>? latestFeedback;

  int get activeDays => activeDates.length;

  bool? get d1Retained => _retainedAtDay(1);
  bool? get d7Retained => _retainedAtDay(7);

  bool? _retainedAtDay(int day) {
    if (firstOpen == null) return null;
    final first = DateTime(
      firstOpen!.year,
      firstOpen!.month,
      firstOpen!.day,
    );
    final now = DateTime.now();
    final age = DateTime(now.year, now.month, now.day).difference(first).inDays;
    if (age < day) return null;
    final target = first.add(Duration(days: day));
    final key = _dateKey(target);
    return activeDates.contains(key);
  }

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class LearningTelemetryService {
  const LearningTelemetryService();

  static const _key = 'dataquest_learning_health_v1';

  Future<void> recordAppOpen() async {
    final state = await _load();
    final now = DateTime.now();
    final dates = Set<String>.from(
      (state['activeDates'] as List<dynamic>?) ?? const <dynamic>[],
    )..add(_dateKey(now));
    state['firstOpen'] ??= now.toIso8601String();
    state['activeDates'] = dates.toList()..sort();
    state['appOpens'] = ((state['appOpens'] as num?)?.toInt() ?? 0) + 1;
    await _save(state);
  }

  Future<void> recordEvent(String event) async {
    final state = await _load();
    final key = switch (event) {
      'workday_start' => 'workdayStarts',
      'workday_complete' => 'workdayCompletions',
      _ => 'event_$event',
    };
    state[key] = ((state[key] as num?)?.toInt() ?? 0) + 1;
    if (event == 'workday_complete' &&
        state['firstFlagshipCompletedAt'] == null) {
      state['firstFlagshipCompletedAt'] =
          DateTime.now().toUtc().toIso8601String();
    }
    await _save(state);
  }

  Future<void> saveFeedback({
    required int realism,
    required int usefulness,
    required String confusion,
    required String wouldPay,
    required String freeText,
  }) async {
    final state = await _load();
    final feedback = List<Map<String, dynamic>>.from(
      ((state['feedback'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
    feedback.add({
      'submittedAt': DateTime.now().toUtc().toIso8601String(),
      'realism': realism,
      'usefulness': usefulness,
      'confusion': confusion.trim(),
      'wouldPay': wouldPay,
      'freeText': freeText.trim(),
    });
    state['feedback'] = feedback;
    await _save(state);
  }

  Future<LearningHealthReport> report() async {
    final state = await _load();
    final feedback = List<Map<String, dynamic>>.from(
      ((state['feedback'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
    return LearningHealthReport(
      firstOpen: state['firstOpen'] == null
          ? null
          : DateTime.parse(state['firstOpen'] as String),
      activeDates: List<String>.from(
        (state['activeDates'] as List<dynamic>?) ?? const <dynamic>[],
      ),
      appOpens: (state['appOpens'] as num?)?.toInt() ?? 0,
      workdayStarts: (state['workdayStarts'] as num?)?.toInt() ?? 0,
      stageCompletions: {
        for (final stage in const ['quality', 'tool', 'analysis', 'statistics', 'chart', 'manager'])
          stage: (state['event_stage_${stage}_complete'] as num?)?.toInt() ?? 0,
      },
      workdayCompletions:
          (state['workdayCompletions'] as num?)?.toInt() ?? 0,
      firstFlagshipCompletedAt: state['firstFlagshipCompletedAt'] == null
          ? null
          : DateTime.parse(state['firstFlagshipCompletedAt'] as String),
      feedbackCount: feedback.length,
      latestFeedback: feedback.isEmpty ? null : feedback.last,
    );
  }

  Future<Map<String, dynamic>> exportJson() => _load();

  Future<Map<String, dynamic>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    return Map<String, dynamic>.from(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> _save(Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state));
  }

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
