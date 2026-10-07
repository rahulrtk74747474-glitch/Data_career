import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/analyst_task.dart';
import '../../services/learning_reward_service.dart';

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
    this.completedEventIds = const <String>{},
    this.rewardedLearningIds = const <String>{},
    this.managerTrust = 50,
    this.dataQuality = 60,
    this.riskIndex = 50,
    this.manualNotes = const <String>[],
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
      completedEventIds: <String>{},
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
  final Set<String> completedEventIds;
  final Set<String> rewardedLearningIds;
  final double managerTrust;
  final double dataQuality;

  /// Lower is better. This represents simulated decision/operational risk.
  final double riskIndex;
  final List<String> manualNotes;

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
    Set<String>? completedEventIds,
    Set<String>? rewardedLearningIds,
    double? managerTrust,
    double? dataQuality,
    double? riskIndex,
    List<String>? manualNotes,
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
      completedEventIds: completedEventIds ?? this.completedEventIds,
      rewardedLearningIds: rewardedLearningIds ?? this.rewardedLearningIds,
      managerTrust: managerTrust ?? this.managerTrust,
      dataQuality: dataQuality ?? this.dataQuality,
      riskIndex: riskIndex ?? this.riskIndex,
      manualNotes: manualNotes ?? this.manualNotes,
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
      'completedEventIds': completedEventIds.toList(),
      'rewardedLearningIds': rewardedLearningIds.toList(),
      'managerTrust': managerTrust,
      'dataQuality': dataQuality,
      'riskIndex': riskIndex,
      'manualNotes': manualNotes,
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
      completedEventIds: Set<String>.from(
        (json['completedEventIds'] as List<dynamic>?) ??
            const <dynamic>[],
      ),
      rewardedLearningIds: Set<String>.from(
        (json['rewardedLearningIds'] as List<dynamic>?) ??
            const <dynamic>[],
      ),
      managerTrust: (json['managerTrust'] as num?)?.toDouble() ?? 50,
      dataQuality: (json['dataQuality'] as num?)?.toDouble() ?? 60,
      riskIndex: (json['riskIndex'] as num?)?.toDouble() ?? 50,
      manualNotes: List<String>.from(
        (json['manualNotes'] as List<dynamic>?) ?? const <dynamic>[],
      ),
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
    bool solutionViewed = false,
  }) async {
    if (state.completedTaskIds.contains(task.id)) return;

    final earnedXp = LearningRewardService.earnedXp(
      baseXp: task.xp,
      score: score,
      solutionViewed: solutionViewed,
    );
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

    final trustDelta = score >= 80
        ? 0.8 * impact
        : score >= 70
            ? 0.3 * impact
            : -0.7;
    final qualityDelta = task.skillKey == 'cleaning'
        ? 1.5 * impact
        : task.skillKey == 'sql' || task.skillKey == 'powerbi'
            ? 0.5 * impact
            : 0.2 * impact;

    state = state.copyWith(
      xp: state.xp + earnedXp,
      streak: state.streak + 1,
      completedTaskIds: completed,
      revenueIndex: revenue,
      churnRate: churn.clamp(0, 100).toDouble(),
      costIndex: costs,
      satisfaction: satisfaction.clamp(0, 100).toDouble(),
      managerTrust:
          (state.managerTrust + trustDelta).clamp(0, 100).toDouble(),
      dataQuality:
          (state.dataQuality + qualityDelta).clamp(0, 100).toDouble(),
    );

    await _save();
  }

  Future<void> completeDailyChallenge({
    required String dateKey,
    required int score,
    required int bonusXp,
    bool solutionViewed = false,
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

    final earnedXp = LearningRewardService.earnedXp(
      baseXp: bonusXp,
      score: score,
      solutionViewed: solutionViewed,
    );
    state = state.copyWith(
      xp: state.xp + earnedXp,
      dailyStreak: nextDailyStreak,
      lastDailyDate: dateKey,
      completedDailyDates: <String>{...state.completedDailyDates, dateKey},
    );
    await _save();
  }

  Future<int> awardLearningXp({
    required String rewardId,
    required int baseXp,
    required int score,
    bool solutionViewed = false,
  }) async {
    if (state.rewardedLearningIds.contains(rewardId)) return 0;
    final earnedXp = LearningRewardService.earnedXp(
      baseXp: baseXp,
      score: score,
      solutionViewed: solutionViewed,
    );
    state = state.copyWith(
      xp: state.xp + earnedXp,
      managerTrust: rewardId.startsWith('mission:')
          ? (state.managerTrust + 2).clamp(0, 100).toDouble()
          : state.managerTrust,
      rewardedLearningIds: <String>{
        ...state.rewardedLearningIds,
        rewardId,
      },
    );
    await _save();
    return earnedXp;
  }

  Future<int> applyWorkDecision({
    required String decisionId,
    required int baseXp,
    required int score,
    double revenueDelta = 0,
    double churnDelta = 0,
    double costDelta = 0,
    double satisfactionDelta = 0,
    double trustDelta = 0,
    double dataQualityDelta = 0,
    double riskDelta = 0,
  }) async {
    final rewardId = 'decision:$decisionId';
    if (state.rewardedLearningIds.contains(rewardId)) return 0;

    final earnedXp = LearningRewardService.earnedXp(
      baseXp: baseXp,
      score: score,
      solutionViewed: false,
    );
    state = state.copyWith(
      xp: state.xp + earnedXp,
      revenueIndex: state.revenueIndex + revenueDelta,
      churnRate: (state.churnRate + churnDelta).clamp(0, 100).toDouble(),
      costIndex: state.costIndex + costDelta,
      satisfaction:
          (state.satisfaction + satisfactionDelta).clamp(0, 100).toDouble(),
      managerTrust:
          (state.managerTrust + trustDelta).clamp(0, 100).toDouble(),
      dataQuality:
          (state.dataQuality + dataQualityDelta).clamp(0, 100).toDouble(),
      riskIndex: (state.riskIndex + riskDelta).clamp(0, 100).toDouble(),
      rewardedLearningIds: <String>{
        ...state.rewardedLearningIds,
        rewardId,
      },
    );
    await _save();
    return earnedXp;
  }

  Future<void> addManualNote(String note) async {
    final cleaned = note.trim();
    if (cleaned.isEmpty) return;
    state = state.copyWith(
      manualNotes: <String>[
        ...state.manualNotes,
        cleaned,
      ],
    );
    await _save();
  }

  Future<void> deleteManualNoteAt(int index) async {
    if (index < 0 || index >= state.manualNotes.length) return;
    final next = <String>[...state.manualNotes]..removeAt(index);
    state = state.copyWith(manualNotes: next);
    await _save();
  }

  Future<void> applyRandomEvent({
    required String eventId,
    required double revenueDelta,
    required double churnDelta,
    required double costDelta,
    required double satisfactionDelta,
  }) async {
    if (state.completedEventIds.contains(eventId)) return;

    state = state.copyWith(
      completedEventIds: <String>{...state.completedEventIds, eventId},
      revenueIndex: state.revenueIndex + revenueDelta,
      churnRate: (state.churnRate + churnDelta).clamp(0, 100).toDouble(),
      costIndex: state.costIndex + costDelta,
      satisfaction:
          (state.satisfaction + satisfactionDelta).clamp(0, 100).toDouble(),
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

  Future<void> restoreFromBackup(GameProgress progress) async {
    state = progress;
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
