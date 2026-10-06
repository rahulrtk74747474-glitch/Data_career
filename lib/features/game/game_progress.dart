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
    required this.careerLevel,
    required this.dailyStreak,
    required this.lastDailyDate,
    required this.completedDailyDates,
    this.companyChapter = -1,
    this.companyJourneyCompleted = false,
  });

  static const roleNames = [
    'Data Analyst Intern',
    'Junior Data Analyst',
    'Data Analyst',
    'Senior Analyst',
    'Lead Analyst',
    'Head of Analytics',
  ];

  static const companyKeys = [
    'ecommerce',
    'saas',
    'bank',
    'hospital',
    'logistics',
  ];

  static const companyNames = [
    'E-commerce Co.',
    'SaaS Growth Co.',
    'NorthStar Bank Analytics',
    'Harborview Hospital Analytics',
    'Logistics Network Co.',
  ];

  static const xpThresholds = [200, 500, 900, 1400, 2000];

  factory GameProgress.initial() {
    return const GameProgress(
      xp: 0,
      streak: 0,
      completedTaskIds: <String>{},
      revenueIndex: 100,
      churnRate: 8.0,
      costIndex: 100,
      satisfaction: 70,
      careerLevel: 0,
      dailyStreak: 0,
      lastDailyDate: null,
      completedDailyDates: <String>{},
      companyChapter: 0,
      companyJourneyCompleted: false,
    );
  }

  final int xp;
  final int streak;
  final Set<String> completedTaskIds;
  final double revenueIndex;
  final double churnRate;
  final double costIndex;
  final double satisfaction;
  final int careerLevel;
  final int dailyStreak;
  final String? lastDailyDate;
  final Set<String> completedDailyDates;

  /// -1 is accepted only for source/backward compatibility in tests and
  /// manually constructed objects. Persisted progress always stores a
  /// concrete independent chapter.
  final int companyChapter;
  final bool companyJourneyCompleted;

  int get resolvedCompanyChapter {
    if (companyChapter >= 0) {
      return companyChapter.clamp(0, companyKeys.length - 1).toInt();
    }
    return _legacyCompanyChapterFromCareerLevel(careerLevel);
  }

  String get role => roleNames[careerLevel.clamp(0, 5).toInt()];

  String get companyKey => companyKeys[resolvedCompanyChapter];

  String get companyName => companyNames[resolvedCompanyChapter];

  String get companyStageLabel {
    switch (companyKey) {
      case 'hospital':
        return 'Harborview Hospital Analytics • Operations & Capacity';
      case 'bank':
        return 'NorthStar Bank Analytics • Risk & Operations';
      case 'saas':
        return 'SaaS Growth Co. • Growth team';
      case 'logistics':
        return 'Logistics Network Co. • Network Operations';
      default:
        return 'E-commerce Co. • Commercial Analytics';
    }
  }

  bool get isTopRole => careerLevel >= roleNames.length - 1;

  bool get isFinalAvailableCompanyChapter => resolvedCompanyChapter >= 4;

  String? get nextCompanyName {
    if (isFinalAvailableCompanyChapter) return null;
    return companyNames[resolvedCompanyChapter + 1];
  }

  int get nextRoleXp {
    if (isTopRole) return xpThresholds.last;
    return xpThresholds[careerLevel];
  }

  double get roleProgress {
    if (isTopRole) return 1;
    final previous = careerLevel == 0 ? 0 : xpThresholds[careerLevel - 1];
    final span = nextRoleXp - previous;
    if (span <= 0) return 1;
    return ((xp - previous) / span).clamp(0, 1).toDouble();
  }

  bool completedDaily(String dateKey) => completedDailyDates.contains(dateKey);

  GameProgress copyWith({
    int? xp,
    int? streak,
    Set<String>? completedTaskIds,
    double? revenueIndex,
    double? churnRate,
    double? costIndex,
    double? satisfaction,
    int? careerLevel,
    int? dailyStreak,
    String? lastDailyDate,
    bool clearLastDailyDate = false,
    Set<String>? completedDailyDates,
    int? companyChapter,
    bool? companyJourneyCompleted,
  }) {
    return GameProgress(
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      completedTaskIds: completedTaskIds ?? this.completedTaskIds,
      revenueIndex: revenueIndex ?? this.revenueIndex,
      churnRate: churnRate ?? this.churnRate,
      costIndex: costIndex ?? this.costIndex,
      satisfaction: satisfaction ?? this.satisfaction,
      careerLevel: careerLevel ?? this.careerLevel,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastDailyDate:
          clearLastDailyDate ? null : (lastDailyDate ?? this.lastDailyDate),
      completedDailyDates: completedDailyDates ?? this.completedDailyDates,
      companyChapter: companyChapter ?? resolvedCompanyChapter,
      companyJourneyCompleted:
          companyJourneyCompleted ?? this.companyJourneyCompleted,
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
      'careerLevel': careerLevel,
      'dailyStreak': dailyStreak,
      'lastDailyDate': lastDailyDate,
      'completedDailyDates': completedDailyDates.toList(),
      'companyChapter': resolvedCompanyChapter,
      'companyJourneyCompleted': companyJourneyCompleted,
    };
  }

  factory GameProgress.fromJson(Map<String, dynamic> json) {
    final xp = (json['xp'] as num?)?.toInt() ?? 0;
    final savedLevel = (json['careerLevel'] as num?)?.toInt();
    final careerLevel =
        (savedLevel ?? _legacyLevelFromXp(xp)).clamp(0, 5).toInt();
    final savedChapter = (json['companyChapter'] as num?)?.toInt();

    return GameProgress(
      xp: xp,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      completedTaskIds: Set<String>.from(
        (json['completedTaskIds'] as List<dynamic>?) ?? const <dynamic>[],
      ),
      revenueIndex: (json['revenueIndex'] as num?)?.toDouble() ?? 100,
      churnRate: (json['churnRate'] as num?)?.toDouble() ?? 8,
      costIndex: (json['costIndex'] as num?)?.toDouble() ?? 100,
      satisfaction: (json['satisfaction'] as num?)?.toDouble() ?? 70,
      careerLevel: careerLevel,
      dailyStreak: (json['dailyStreak'] as num?)?.toInt() ?? 0,
      lastDailyDate: json['lastDailyDate'] as String?,
      completedDailyDates: Set<String>.from(
        (json['completedDailyDates'] as List<dynamic>?) ??
            const <dynamic>[],
      ),
      companyChapter: (savedChapter ??
              _legacyCompanyChapterFromCareerLevel(careerLevel))
          .clamp(0, companyKeys.length - 1)
          .toInt(),
      companyJourneyCompleted:
          (json['companyJourneyCompleted'] as bool?) ?? false,
    );
  }

  static int _legacyLevelFromXp(int xp) {
    if (xp >= 2000) return 5;
    if (xp >= 1400) return 4;
    if (xp >= 900) return 3;
    if (xp >= 500) return 2;
    if (xp >= 200) return 1;
    return 0;
  }

  static int _legacyCompanyChapterFromCareerLevel(int careerLevel) {
    if (careerLevel >= 4) return 2;
    if (careerLevel >= 2) return 1;
    return 0;
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

    await _save();
  }

  Future<void> completeDailyChallenge({
    required String dateKey,
    required int score,
    required int bonusXp,
  }) async {
    if (state.completedDaily(dateKey)) return;

    final currentDate = DateTime.tryParse(dateKey);
    final previousDate = state.lastDailyDate == null
        ? null
        : DateTime.tryParse(state.lastDailyDate!);
    var nextDailyStreak = 1;

    if (currentDate != null && previousDate != null) {
      final difference = currentDate.difference(previousDate).inDays;
      if (difference == 1) {
        nextDailyStreak = state.dailyStreak + 1;
      }
    }

    final earnedXp = (bonusXp * score / 100).round();
    state = state.copyWith(
      xp: state.xp + earnedXp,
      dailyStreak: nextDailyStreak,
      lastDailyDate: dateKey,
      completedDailyDates: <String>{...state.completedDailyDates, dateKey},
    );
    await _save();
  }

  Future<void> promote() async {
    if (state.isTopRole) return;
    state = state.copyWith(careerLevel: state.careerLevel + 1);
    await _save();
  }

  Future<void> advanceCompanyChapter() async {
    if (state.resolvedCompanyChapter >= 4) return;
    state = state.copyWith(
      companyChapter: state.resolvedCompanyChapter + 1,
      companyJourneyCompleted: false,
    );
    await _save();
  }

  Future<void> completeCompanyJourney() async {
    if (state.resolvedCompanyChapter < 4) return;
    if (state.companyJourneyCompleted) return;
    state = state.copyWith(companyJourneyCompleted: true);
    await _save();
  }

  Future<void> reset() async {
    state = GameProgress.initial();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }
}
