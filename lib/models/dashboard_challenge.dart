class DashboardChallenge {
  const DashboardChallenge({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.category,
    required this.context,
    required this.prompt,
    required this.options,
    required this.correctOption,
    required this.hints,
    required this.explanation,
    this.xp = 90,
    this.skillKey = 'business',
    this.companyKey = 'training',
  });

  final String id;
  final String title;
  final String difficulty;
  final String category;
  final String context;
  final String prompt;
  final List<String> options;
  final String correctOption;
  final List<String> hints;
  final String explanation;
  final int xp;
  final String skillKey;
  final String companyKey;

  String get solutionText =>
      'Correct decision:\n$correctOption\n\nWhy:\n$explanation';

  factory DashboardChallenge.fromJson(Map<String, dynamic> json) {
    return DashboardChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      difficulty: json['difficulty'] as String,
      category: json['category'] as String,
      context: json['context'] as String,
      prompt: json['prompt'] as String,
      options: List<String>.from(json['options'] as List<dynamic>),
      correctOption: json['correctOption'] as String,
      hints: List<String>.from(json['hints'] as List<dynamic>),
      explanation: json['explanation'] as String,
      xp: (json['xp'] as num?)?.toInt() ?? 90,
      skillKey: (json['skillKey'] as String?) ?? 'business',
      companyKey: (json['companyKey'] as String?) ?? 'training',
    );
  }
}
