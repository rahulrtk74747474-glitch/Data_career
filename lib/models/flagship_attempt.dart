class FlagshipAttempt {
  const FlagshipAttempt({
    required this.workdayId,
    this.completedStages = const <String>{},
    this.selectedIssues = const <String>{},
    this.tool = '',
    this.analysisText = '',
    this.statisticsAnswer = '',
    this.chartAnswer = '',
    this.managerText = '',
    this.hintsUsed = 0,
    this.changedDataPassed = false,
    this.issueScore = 0,
    this.toolScore = 0,
    this.analysisScore = 0,
    this.statisticsScore = 0,
    this.chartScore = 0,
    this.managerScore = 0,
    this.totalScore = 0,
    this.completedAt,
  });

  final String workdayId;
  final Set<String> completedStages;
  final Set<String> selectedIssues;
  final String tool;
  final String analysisText;
  final String statisticsAnswer;
  final String chartAnswer;
  final String managerText;
  final int hintsUsed;
  /// Passed a query-output check on an altered, rollback-only fixture.
  final bool changedDataPassed;
  final int issueScore;
  final int toolScore;
  final int analysisScore;
  final int statisticsScore;
  final int chartScore;
  final int managerScore;
  final int totalScore;
  final DateTime? completedAt;

  bool stageDone(String stage) => completedStages.contains(stage);
  bool get isComplete => completedAt != null;

  FlagshipAttempt copyWith({
    Set<String>? completedStages,
    Set<String>? selectedIssues,
    String? tool,
    String? analysisText,
    String? statisticsAnswer,
    String? chartAnswer,
    String? managerText,
    int? hintsUsed,
    bool? changedDataPassed,
    int? issueScore,
    int? toolScore,
    int? analysisScore,
    int? statisticsScore,
    int? chartScore,
    int? managerScore,
    int? totalScore,
    DateTime? completedAt,
  }) {
    return FlagshipAttempt(
      workdayId: workdayId,
      completedStages: completedStages ?? this.completedStages,
      selectedIssues: selectedIssues ?? this.selectedIssues,
      tool: tool ?? this.tool,
      analysisText: analysisText ?? this.analysisText,
      statisticsAnswer: statisticsAnswer ?? this.statisticsAnswer,
      chartAnswer: chartAnswer ?? this.chartAnswer,
      managerText: managerText ?? this.managerText,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      changedDataPassed: changedDataPassed ?? this.changedDataPassed,
      issueScore: issueScore ?? this.issueScore,
      toolScore: toolScore ?? this.toolScore,
      analysisScore: analysisScore ?? this.analysisScore,
      statisticsScore: statisticsScore ?? this.statisticsScore,
      chartScore: chartScore ?? this.chartScore,
      managerScore: managerScore ?? this.managerScore,
      totalScore: totalScore ?? this.totalScore,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'workdayId': workdayId,
        'completedStages': completedStages.toList(),
        'selectedIssues': selectedIssues.toList(),
        'tool': tool,
        'analysisText': analysisText,
        'statisticsAnswer': statisticsAnswer,
        'chartAnswer': chartAnswer,
        'managerText': managerText,
        'hintsUsed': hintsUsed,
        'changedDataPassed': changedDataPassed,
        'issueScore': issueScore,
        'toolScore': toolScore,
        'analysisScore': analysisScore,
        'statisticsScore': statisticsScore,
        'chartScore': chartScore,
        'managerScore': managerScore,
        'totalScore': totalScore,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory FlagshipAttempt.fromJson(Map<String, dynamic> json) =>
      FlagshipAttempt(
        workdayId: json['workdayId'] as String,
        completedStages: Set<String>.from(
          (json['completedStages'] as List<dynamic>?) ?? const <dynamic>[],
        ),
        selectedIssues: Set<String>.from(
          (json['selectedIssues'] as List<dynamic>?) ?? const <dynamic>[],
        ),
        tool: (json['tool'] as String?) ?? '',
        analysisText: (json['analysisText'] as String?) ?? '',
        statisticsAnswer: (json['statisticsAnswer'] as String?) ?? '',
        chartAnswer: (json['chartAnswer'] as String?) ?? '',
        managerText: (json['managerText'] as String?) ?? '',
        hintsUsed: (json['hintsUsed'] as num?)?.toInt() ?? 0,
        changedDataPassed: json['changedDataPassed'] == true,
        issueScore: (json['issueScore'] as num?)?.toInt() ?? 0,
        toolScore: (json['toolScore'] as num?)?.toInt() ?? 0,
        analysisScore: (json['analysisScore'] as num?)?.toInt() ?? 0,
        statisticsScore: (json['statisticsScore'] as num?)?.toInt() ?? 0,
        chartScore: (json['chartScore'] as num?)?.toInt() ?? 0,
        managerScore: (json['managerScore'] as num?)?.toInt() ?? 0,
        totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
      );
}
