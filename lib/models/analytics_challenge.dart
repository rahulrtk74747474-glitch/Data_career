class AnalyticsChallenge {
  const AnalyticsChallenge({
    required this.id,
    required this.title,
    required this.mode,
    required this.skillKey,
    required this.difficulty,
    required this.companyKey,
    required this.context,
    required this.prompt,
    required this.options,
    required this.expectedAnswer,
    required this.chartOptions,
    required this.expectedChart,
    required this.kpiOptions,
    required this.expectedKpis,
    required this.insightPrompt,
    required this.evidenceTerms,
    required this.recommendationTerms,
    required this.impactTerms,
    required this.hints,
    required this.explanation,
    required this.xp,
  });

  final String id;
  final String title;
  final String mode;
  final String skillKey;
  final String difficulty;
  final String companyKey;
  final String context;
  final String prompt;
  final List<String> options;
  final String expectedAnswer;
  final List<String> chartOptions;
  final String expectedChart;
  final List<String> kpiOptions;
  final List<String> expectedKpis;
  final String insightPrompt;
  final List<String> evidenceTerms;
  final List<String> recommendationTerms;
  final List<String> impactTerms;
  final List<String> hints;
  final String explanation;
  final int xp;

  bool get isDashboard => mode == 'dashboard';

  String get solutionText {
    if (isDashboard) {
      return 'Correct chart: $expectedChart\n'
          'Correct KPIs: ${expectedKpis.join(', ')}\n\n'
          'Why:\n$explanation';
    }
    return 'Correct interpretation:\n$expectedAnswer\n\nWhy:\n$explanation';
  }

  factory AnalyticsChallenge.fromJson(Map<String, dynamic> json) {
    return AnalyticsChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      mode: json['mode'] as String,
      skillKey: json['skillKey'] as String,
      difficulty: json['difficulty'] as String,
      companyKey: json['companyKey'] as String,
      context: json['context'] as String,
      prompt: json['prompt'] as String,
      options: List<String>.from(
        json['options'] as List<dynamic>? ?? const [],
      ),
      expectedAnswer: json['expectedAnswer'] as String? ?? '',
      chartOptions: List<String>.from(
        json['chartOptions'] as List<dynamic>? ?? const [],
      ),
      expectedChart: json['expectedChart'] as String? ?? '',
      kpiOptions: List<String>.from(
        json['kpiOptions'] as List<dynamic>? ?? const [],
      ),
      expectedKpis: List<String>.from(
        json['expectedKpis'] as List<dynamic>? ?? const [],
      ),
      insightPrompt: json['insightPrompt'] as String,
      evidenceTerms: List<String>.from(
        json['evidenceTerms'] as List<dynamic>? ?? const [],
      ),
      recommendationTerms: List<String>.from(
        json['recommendationTerms'] as List<dynamic>? ?? const [],
      ),
      impactTerms: List<String>.from(
        json['impactTerms'] as List<dynamic>? ?? const [],
      ),
      hints: List<String>.from(json['hints'] as List<dynamic>),
      explanation: json['explanation'] as String,
      xp: (json['xp'] as num).toInt(),
    );
  }
}
