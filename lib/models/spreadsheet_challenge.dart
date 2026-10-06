class SpreadsheetChallenge {
  const SpreadsheetChallenge({
    required this.id,
    required this.title,
    required this.skillKey,
    required this.difficulty,
    required this.companyKey,
    required this.context,
    required this.prompt,
    required this.datasetName,
    required this.rows,
    required this.expectedCommand,
    required this.expectedRows,
    required this.hints,
    required this.explanation,
    required this.xp,
  });

  final String id;
  final String title;
  final String skillKey;
  final String difficulty;
  final String companyKey;
  final String context;
  final String prompt;
  final String datasetName;
  final List<Map<String, dynamic>> rows;
  final String expectedCommand;
  final List<Map<String, dynamic>> expectedRows;
  final List<String> hints;
  final String explanation;
  final int xp;

  bool get isFormula => expectedRows.isEmpty;

  factory SpreadsheetChallenge.fromJson(Map<String, dynamic> json) {
    return SpreadsheetChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      skillKey: json['skillKey'] as String,
      difficulty: json['difficulty'] as String,
      companyKey: json['companyKey'] as String,
      context: json['context'] as String,
      prompt: json['prompt'] as String,
      datasetName: json['datasetName'] as String,
      rows: (json['rows'] as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      expectedCommand: json['expectedCommand'] as String,
      expectedRows: ((json['expectedRows'] as List<dynamic>?) ??
              const <dynamic>[])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      hints: List<String>.from(json['hints'] as List<dynamic>),
      explanation: json['explanation'] as String,
      xp: (json['xp'] as num).toInt(),
    );
  }
}
