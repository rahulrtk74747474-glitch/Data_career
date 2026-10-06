class InterviewCriterion {
  const InterviewCriterion({
    required this.label,
    required this.weight,
    required this.keywords,
  });

  final String label;
  final int weight;
  final List<String> keywords;

  factory InterviewCriterion.fromJson(Map<String, dynamic> json) {
    return InterviewCriterion(
      label: json['label'] as String,
      weight: (json['weight'] as num).toInt(),
      keywords: List<String>.from(json['keywords'] as List<dynamic>),
    );
  }
}

class InterviewQuestion {
  const InterviewQuestion({
    required this.id,
    required this.context,
    required this.prompt,
    required this.answerType,
    required this.options,
    required this.expectedAnswer,
    required this.expectedRows,
    required this.criteria,
    required this.explanation,
  });

  final String id;
  final String context;
  final String prompt;
  final String answerType;
  final List<String> options;
  final String expectedAnswer;
  final List<Map<String, dynamic>> expectedRows;
  final List<InterviewCriterion> criteria;
  final String explanation;

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) {
    return InterviewQuestion(
      id: json['id'] as String,
      context: json['context'] as String,
      prompt: json['prompt'] as String,
      answerType: json['answerType'] as String,
      options: List<String>.from(
        (json['options'] as List<dynamic>?) ?? const <dynamic>[],
      ),
      expectedAnswer: (json['expectedAnswer'] as String?) ?? '',
      expectedRows: ((json['expectedRows'] as List<dynamic>?) ??
              const <dynamic>[])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      criteria: ((json['criteria'] as List<dynamic>?) ?? const <dynamic>[])
          .map(
            (item) => InterviewCriterion.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      explanation: json['explanation'] as String,
    );
  }
}

class InterviewRoundDefinition {
  const InterviewRoundDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.durationSeconds,
    required this.questions,
    this.companyKey = 'general',
    this.minCompanyChapter = 0,
  });

  final String key;
  final String title;
  final String description;
  final int durationSeconds;
  final List<InterviewQuestion> questions;
  final String companyKey;
  final int minCompanyChapter;

  factory InterviewRoundDefinition.fromJson(Map<String, dynamic> json) {
    return InterviewRoundDefinition(
      key: json['key'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      questions: (json['questions'] as List<dynamic>)
          .map(
            (item) => InterviewQuestion.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      companyKey: (json['companyKey'] as String?) ?? 'general',
      minCompanyChapter:
          (json['minCompanyChapter'] as num?)?.toInt() ?? 0,
    );
  }
}
