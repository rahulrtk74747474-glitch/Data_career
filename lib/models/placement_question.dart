class PlacementQuestion {
  const PlacementQuestion({
    required this.id,
    required this.skillKey,
    required this.question,
    required this.options,
    required this.correctOption,
    required this.explanation,
  });

  final String id;
  final String skillKey;
  final String question;
  final List<String> options;
  final String correctOption;
  final String explanation;

  factory PlacementQuestion.fromJson(Map<String, dynamic> json) {
    return PlacementQuestion(
      id: json['id'] as String,
      skillKey: json['skillKey'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List<dynamic>),
      correctOption: json['correctOption'] as String,
      explanation: json['explanation'] as String,
    );
  }
}
