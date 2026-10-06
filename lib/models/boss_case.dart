class BossCaseDefinition {
  const BossCaseDefinition({
    required this.id,
    required this.title,
    required this.company,
    required this.context,
    required this.datasetName,
    required this.cleaningPrompt,
    required this.cleaningOptions,
    required this.cleaningExpectedSelections,
    required this.sqlPrompt,
    required this.sqlExpectedRows,
    required this.kpiPrompt,
    required this.kpiExpected,
    required this.kpiTolerance,
    required this.chartPrompt,
    required this.chartOptions,
    required this.chartExpected,
    required this.recommendationPrompt,
    required this.recommendationOptions,
    required this.recommendationExpected,
    required this.rubric,
    this.companyKey = 'ecommerce',
    this.minCareerLevel = 0,
  });

  final String id;
  final String title;
  final String company;
  final String context;
  final String datasetName;
  final String cleaningPrompt;
  final List<String> cleaningOptions;
  final List<String> cleaningExpectedSelections;
  final String sqlPrompt;
  final List<Map<String, dynamic>> sqlExpectedRows;
  final String kpiPrompt;
  final double kpiExpected;
  final double kpiTolerance;
  final String chartPrompt;
  final List<String> chartOptions;
  final String chartExpected;
  final String recommendationPrompt;
  final List<String> recommendationOptions;
  final String recommendationExpected;
  final Map<String, int> rubric;
  final String companyKey;
  final int minCareerLevel;

  factory BossCaseDefinition.fromJson(Map<String, dynamic> json) {
    return BossCaseDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String,
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
      kpiPrompt: json['kpiPrompt'] as String,
      kpiExpected: (json['kpiExpected'] as num).toDouble(),
      kpiTolerance: (json['kpiTolerance'] as num).toDouble(),
      chartPrompt: json['chartPrompt'] as String,
      chartOptions: List<String>.from(json['chartOptions'] as List<dynamic>),
      chartExpected: json['chartExpected'] as String,
      recommendationPrompt: json['recommendationPrompt'] as String,
      recommendationOptions:
          List<String>.from(json['recommendationOptions'] as List<dynamic>),
      recommendationExpected: json['recommendationExpected'] as String,
      rubric: Map<String, int>.from(json['rubric'] as Map),
      companyKey: (json['companyKey'] as String?) ?? 'ecommerce',
      minCareerLevel: (json['minCareerLevel'] as num?)?.toInt() ?? 0,
    );
  }

  int weight(String key) => rubric[key] ?? 0;
}
