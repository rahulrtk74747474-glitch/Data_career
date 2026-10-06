class PandasChallenge {
  const PandasChallenge({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.context,
    required this.datasetName,
    required this.rows,
    required this.prompt,
    required this.requiredFragments,
    required this.operation,
    required this.expectedRows,
    required this.hints,
    required this.explanation,
    required this.xp,
  });

  final String id;
  final String title;
  final String difficulty;
  final String context;
  final String datasetName;
  final List<Map<String, dynamic>> rows;
  final String prompt;
  final List<String> requiredFragments;
  final Map<String, dynamic> operation;
  final List<Map<String, dynamic>> expectedRows;
  final List<String> hints;
  final String explanation;
  final int xp;

  factory PandasChallenge.fromJson(Map<String, dynamic> json) {
    return PandasChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      difficulty: json['difficulty'] as String,
      context: json['context'] as String,
      datasetName: json['datasetName'] as String,
      rows: (json['rows'] as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      prompt: json['prompt'] as String,
      requiredFragments:
          List<String>.from(json['requiredFragments'] as List<dynamic>),
      operation: Map<String, dynamic>.from(json['operation'] as Map),
      expectedRows: (json['expectedRows'] as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      hints: List<String>.from(json['hints'] as List<dynamic>),
      explanation: json['explanation'] as String,
      xp: json['xp'] as int,
    );
  }
}
