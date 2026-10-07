class FoundationLesson {
  const FoundationLesson({
    required this.id,
    required this.skillKey,
    required this.trackKey,
    required this.trackTitle,
    required this.order,
    required this.title,
    required this.companyKey,
    required this.concept,
    required this.explanation,
    required this.scenario,
    required this.workedExample,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.hints,
    required this.solution,
    required this.xp,
  });

  final String id;
  final String skillKey;
  final String trackKey;
  final String trackTitle;
  final int order;
  final String title;
  final String companyKey;
  final String concept;
  final String explanation;
  final String scenario;
  final String workedExample;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final List<String> hints;
  final String solution;
  final int xp;

  factory FoundationLesson.fromJson(Map<String, dynamic> json) {
    return FoundationLesson(
      id: json['id'] as String,
      skillKey: json['skillKey'] as String,
      trackKey: json['trackKey'] as String,
      trackTitle: json['trackTitle'] as String,
      order: (json['order'] as num).toInt(),
      title: json['title'] as String,
      companyKey: json['companyKey'] as String,
      concept: json['concept'] as String,
      explanation: json['explanation'] as String,
      scenario: json['scenario'] as String,
      workedExample: json['workedExample'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List<dynamic>),
      correctAnswer: json['correctAnswer'] as String,
      hints: List<String>.from(json['hints'] as List<dynamic>),
      solution: json['solution'] as String,
      xp: (json['xp'] as num).toInt(),
    );
  }
}
