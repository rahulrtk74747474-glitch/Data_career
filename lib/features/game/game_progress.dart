import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/analyst_task.dart';

class GameProgress {
  const GameProgress({
    required this.xp,
    required this.streak,
    required this.completedTaskIds,
    required this.revenueIndex,
    required this.churnRate,
    required this.costIndex,
    required this.satisfaction,
  });

  factory GameProgress.initial() {
    return const GameProgress(
      xp: 0,
      streak: 0,
      completedTaskIds: <String>{},
      revenueIndex: 100,
      churnRate: 8.0,
      costIndex: 100,
      satisfaction: 70,
    );
  }

  final int xp;
  final int streak;
  final Set<String> completedTaskIds;
  final double revenueIndex;
  final double churnRate;
  final double costIndex;
  final double satisfaction;

  String get role {
    if (xp >= 2000) return 'Head of Analytics';
    if (xp >= 1400) return 'Lead Analyst';
    if (xp >= 900) return 'Senior Analyst';
    if (xp >= 500) return 'Data Analyst';
    if (xp >= 200) return 'Junior Data Analyst';
    return 'Data Analyst Intern';
  }

  int get nextRoleXp {
    if (xp < 200) return 200;
    if (xp < 500) return 500;
    if (xp < 900) return 900;
    if (xp < 1400) return 1400;
    if (xp < 2000) return 2000;
    return 2000;
  }

  double get roleProgress {
    if (xp >= 2000) return 1;
    final previous = xp < 200
        ? 0
        : xp < 500
            ? 200
            : xp < 900
                ? 500
                : xp < 1400
                    ? 900
                    : 1400;
    final next = nextRoleXp;
    return (xp - previous) / (next - previous);
  }

  GameProgress copyWith({
    int? xp,
    int? streak,
    Set<String>? completedTaskIds,
    double? revenueIndex,
    double? churnRate,
    double? costIndex,
    double? satisfaction,
  }) {
    return GameProgress(
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      completedTaskIds: completedTaskIds ?? this.completedTaskIds,
      revenueIndex: revenueIndex ?? this.revenueIndex,
      churnRate: churnRate ?? this.churnRate,
      costIndex: costIndex ?? this.costIndex,
      satisfaction: satisfaction ?? this.satisfaction,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'xp': xp,
      'streak': streak,
      'completedTaskIds': completedTaskIds.toList(),
      'revenueIndex': revenueIndex,
      'churnRate': churnRate,
      'costIndex': costIndex,
      'satisfaction': satisfaction,
    };
  }

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    return GameProgress(
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      completedTaskIds: Set<String>.from(
        (json['completedTaskIds'] as List<dynamic>?) ?? const <dynamic>[],
      ),
      revenueIndex: (json['revenueIndex'] as num?)?.toDouble() ?? 100,
      churnRate: (json['churnRate'] as num?)?.toDouble() ?? 8,
      costIndex: (json['costIndex'] as num?)?.toDouble() ?? 100,
      satisfaction: (json['satisfaction'] as num?)?.toDouble() ?? 70,
    );
  }
}

class GameProgressNotifier extends StateNotifier<GameProgress> {
  GameProgressNotifier() : super(GameProgress.initial()) {
    _load();
  }

  static const _storageKey = 'dataquest_progress_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = GameProgress.fromJson(decoded);
    } catch (_) {
      // Corrupt local progress should never block the player from opening the game.
    }
  }

  Future<void> completeTask(
    AnalystTask task, {
    required int score,
  }) async {
    if (state.completedTaskIds.contains(task.id)) return;

    final earnedXp = (task.xp * score / 100).round();
    final completed = <String>{...state.completedTaskIds, task.id};

    var revenue = state.revenueIndex;
    var churn = state.churnRate;
    var costs = state.costIndex;
    var satisfaction = state.satisfaction;

    final impact = score / 100;
    switch (task.department) {
      case 'Sales':
        revenue += 2.5 * impact;
        break;
      case 'Marketing':
        revenue += 1.5 * impact;
        costs -= 1.0 * impact;
        break;
      case 'CEO':
        satisfaction += 1.5 * impact;
        churn -= 0.2 * impact;
        break;
    }

    state = state.copyWith(
      xp: state.xp + earnedXp,
      streak: state.streak + 1,
      completedTaskIds: completed,
      revenueIndex: revenue,
      churnRate: churn.clamp(0, 100).toDouble(),
      costIndex: costs,
      satisfaction: satisfaction.clamp(0, 100).toDouble(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  Future<void> reset() async {
    state = GameProgress.initial();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
