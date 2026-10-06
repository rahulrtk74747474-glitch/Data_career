class AnalystTask {
  const AnalystTask({
    required this.id,
    required this.title,
    required this.department,
    required this.skill,
    required this.skillKey,
    required this.context,
    required this.goal,
    required this.deliverable,
    required this.answerType,
    required this.prompt,
    required this.expectedAnswer,
    required this.requiredTokens,
    required this.expectedRows,
    required this.expectedSelections,
    required this.hints,
    required this.explanation,
    required this.xp,
    required this.datasetName,
    required this.rows,
    required this.options,
  });

  final String id;
  final String title;
  final String department;
  final String skill;
  final String skillKey;
  final String context;
  final String goal;
  final String deliverable;
  final String answerType;
  final String prompt;
  final String expectedAnswer;
  final List<String> requiredTokens;
  final List<Map<String, dynamic>> expectedRows;
  final List<String> expectedSelections;
  final List<String> hints;
  final String explanation;
  final int xp;
  final String datasetName;
  final List<Map<String, dynamic>> rows;
  final List<String> options;

  factory AnalystTask.fromJson(Map<String, dynamic> json) {
    return AnalystTask(
      id: json['id'] as String,
      title: json['title'] as String,
      department: json['department'] as String,
      skill: json['skill'] as String,
      skillKey: (json['skillKey'] as String?) ??
          _fallbackSkillKey(json['skill'] as String),
      context: json['context'] as String,
      goal: json['goal'] as String,
      deliverable: json['deliverable'] as String,
      answerType: json['answerType'] as String,
      prompt: json['prompt'] as String,
      expectedAnswer: (json['expectedAnswer'] as String?) ?? '',
      requiredTokens: List<String>.from(
        (json['requiredTokens'] as List<dynamic>?) ?? const <dynamic>[],
      ),
      expectedRows: ((json['expectedRows'] as List<dynamic>?) ??
              const <dynamic>[])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      expectedSelections: List<String>.from(
        (json['expectedSelections'] as List<dynamic>?) ??
            const <dynamic>[],
      ),
      hints: List<String>.from(json['hints'] as List<dynamic>),
      explanation: json['explanation'] as String,
      xp: json['xp'] as int,
      datasetName: (json['datasetName'] as String?) ?? '',
      rows: ((json['rows'] as List<dynamic>?) ?? const <dynamic>[])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      options: List<String>.from(
        (json['options'] as List<dynamic>?) ?? const <dynamic>[],
      ),
    );
  }

  static String _fallbackSkillKey(String skill) {
    final normalized = skill.toLowerCase();
    if (normalized.contains('spreadsheet')) return 'spreadsheets';
    if (normalized.contains('sql')) return 'sql';
    if (normalized.contains('clean')) return 'cleaning';
    if (normalized.contains('stat')) return 'statistics';
    return 'business';
  }
}
