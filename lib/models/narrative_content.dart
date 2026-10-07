class InsightScenario {
  const InsightScenario({
    required this.id,
    required this.title,
    required this.companyKey,
    required this.difficulty,
    required this.context,
    required this.prompt,
    required this.evidenceTerms,
    required this.recommendationTerms,
    required this.impactTerms,
    this.modelAnswer = '',
    this.xp = 90,
  });

  final String id;
  final String title;
  final String companyKey;
  final String difficulty;
  final String context;
  final String prompt;
  final List<String> evidenceTerms;
  final List<String> recommendationTerms;
  final List<String> impactTerms;
  final String modelAnswer;
  final int xp;

  String get solutionText => modelAnswer.trim().isNotEmpty
      ? modelAnswer.trim()
      : 'Lead with the supplied evidence, keep the claim bounded, recommend one concrete next action, and connect it to the business impact.';

  factory InsightScenario.fromJson(Map<String, dynamic> json) {
    return InsightScenario(
      id: json['id'] as String,
      title: json['title'] as String,
      companyKey: json['companyKey'] as String,
      difficulty: json['difficulty'] as String,
      context: json['context'] as String,
      prompt: json['prompt'] as String,
      evidenceTerms:
          List<String>.from(json['evidenceTerms'] as List<dynamic>),
      recommendationTerms:
          List<String>.from(json['recommendationTerms'] as List<dynamic>),
      impactTerms:
          List<String>.from(json['impactTerms'] as List<dynamic>),
      modelAnswer: (json['modelAnswer'] as String?) ?? '',
      xp: (json['xp'] as num?)?.toInt() ?? 90,
    );
  }
}

class ManagerDialogue {
  const ManagerDialogue({
    required this.minScore,
    required this.title,
    required this.message,
  });

  final int minScore;
  final String title;
  final String message;

  factory ManagerDialogue.fromJson(Map<String, dynamic> json) {
    return ManagerDialogue(
      minScore: (json['minScore'] as num).toInt(),
      title: json['title'] as String,
      message: json['message'] as String,
    );
  }
}

class RandomEventDefinition {
  const RandomEventDefinition({
    required this.id,
    required this.title,
    required this.category,
    required this.context,
    required this.choices,
  });

  final String id;
  final String title;
  final String category;
  final String context;
  final List<RandomEventChoice> choices;

  factory RandomEventDefinition.fromJson(Map<String, dynamic> json) {
    return RandomEventDefinition(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      context: json['context'] as String,
      choices: (json['choices'] as List<dynamic>)
          .map(
            (item) => RandomEventChoice.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class RandomEventChoice {
  const RandomEventChoice({
    required this.text,
    required this.feedback,
    required this.best,
    required this.revenueDelta,
    required this.churnDelta,
    required this.costDelta,
    required this.satisfactionDelta,
  });

  final String text;
  final String feedback;
  final bool best;
  final double revenueDelta;
  final double churnDelta;
  final double costDelta;
  final double satisfactionDelta;

  factory RandomEventChoice.fromJson(Map<String, dynamic> json) {
    return RandomEventChoice(
      text: json['text'] as String,
      feedback: json['feedback'] as String,
      best: json['best'] as bool? ?? false,
      revenueDelta: (json['revenueDelta'] as num? ?? 0).toDouble(),
      churnDelta: (json['churnDelta'] as num? ?? 0).toDouble(),
      costDelta: (json['costDelta'] as num? ?? 0).toDouble(),
      satisfactionDelta:
          (json['satisfactionDelta'] as num? ?? 0).toDouble(),
    );
  }
}
