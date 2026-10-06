class CapstoneDefinition {
  const CapstoneDefinition({
    required this.id,
    required this.title,
    required this.context,
    required this.datasetName,
    required this.cleaningPrompt,
    required this.cleaningOptions,
    required this.cleaningExpectedSelections,
    required this.sqlPrompt,
    required this.sqlExpectedRows,
    required this.statisticsPrompt,
    required this.statisticsOptions,
    required this.statisticsExpected,
    required this.kpiPrompt,
    required this.kpiExpected,
    required this.kpiTolerance,
    required this.dashboardPrompt,
    required this.dashboardOptions,
    required this.dashboardExpected,
    required this.recommendationPrompt,
    required this.recommendationOptions,
    required this.recommendationExpected,
    required this.rubric,
  });

  final String id;
  final String title;
  final String context;
  final String datasetName;
  final String cleaningPrompt;
  final List<String> cleaningOptions;
  final List<String> cleaningExpectedSelections;
  final String sqlPrompt;
  final List<Map<String, dynamic>> sqlExpectedRows;
  final String statisticsPrompt;
  final List<String> statisticsOptions;
  final String statisticsExpected;
  final String kpiPrompt;
  final double kpiExpected;
  final double kpiTolerance;
  final String dashboardPrompt;
  final List<String> dashboardOptions;
  final String dashboardExpected;
  final String recommendationPrompt;
  final List<String> recommendationOptions;
  final String recommendationExpected;
  final Map<String, int> rubric;

  factory CapstoneDefinition.fromJson(Map<String, dynamic> json) {
    return CapstoneDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      context: json['context'] as String,
      datasetName: json['datasetName'] as String,
      cleaningPrompt: json['cleaningPrompt'] as String,
      cleaningOptions:
          List<String>.from(json['cleaningOptions'] as List<dynamic>),
      cleaningExpectedSelections: List<String>.from(
        json['cleaningExpectedSelections'] as List<dynamic>,
      ),
      sqlPrompt: json['sqlPrompt'] as String,
      sqlExpectedRows: (json['sqlExpectedRows'] as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      statisticsPrompt: json['statisticsPrompt'] as String,
      statisticsOptions:
          List<String>.from(json['statisticsOptions'] as List<dynamic>),
      statisticsExpected: json['statisticsExpected'] as String,
      kpiPrompt: json['kpiPrompt'] as String,
      kpiExpected: (json['kpiExpected'] as num).toDouble(),
      kpiTolerance: (json['kpiTolerance'] as num).toDouble(),
      dashboardPrompt: json['dashboardPrompt'] as String,
      dashboardOptions:
          List<String>.from(json['dashboardOptions'] as List<dynamic>),
      dashboardExpected: json['dashboardExpected'] as String,
      recommendationPrompt: json['recommendationPrompt'] as String,
      recommendationOptions:
          List<String>.from(json['recommendationOptions'] as List<dynamic>),
      recommendationExpected: json['recommendationExpected'] as String,
      rubric: Map<String, int>.from(json['rubric'] as Map),
    );
  }

  int weight(String key) => rubric[key] ?? 0;
}
