class ScoredWorkChoice {
  const ScoredWorkChoice({
    required this.text,
    required this.score,
    required this.feedback,
    this.followUp = '',
    this.impact = const <String, double>{},
  });

  final String text;
  final int score;
  final String feedback;
  final String followUp;
  final Map<String, double> impact;

  factory ScoredWorkChoice.fromJson(Map<String, dynamic> json) {
    return ScoredWorkChoice(
      text: json['text'] as String,
      score: (json['score'] as num).toInt(),
      feedback: json['feedback'] as String,
      followUp: (json['followUp'] as String?) ?? '',
      impact: Map<String, double>.from(
        (json['impact'] as Map? ?? const <String, dynamic>{}).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
    );
  }
}

class WorkInboxMessage {
  const WorkInboxMessage({
    required this.id,
    required this.companyKey,
    required this.minCareerLevel,
    required this.sender,
    required this.senderRole,
    required this.subject,
    required this.urgency,
    required this.body,
    required this.choices,
  });

  final String id;
  final String companyKey;
  final int minCareerLevel;
  final String sender;
  final String senderRole;
  final String subject;
  final String urgency;
  final String body;
  final List<ScoredWorkChoice> choices;

  factory WorkInboxMessage.fromJson(Map<String, dynamic> json) {
    return WorkInboxMessage(
      id: json['id'] as String,
      companyKey: json['companyKey'] as String,
      minCareerLevel: (json['minCareerLevel'] as num? ?? 0).toInt(),
      sender: json['sender'] as String,
      senderRole: json['senderRole'] as String,
      subject: json['subject'] as String,
      urgency: json['urgency'] as String,
      body: json['body'] as String,
      choices: (json['choices'] as List<dynamic>)
          .map(
            (item) => ScoredWorkChoice.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class HandbookEntry {
  const HandbookEntry({
    required this.id,
    required this.skill,
    required this.title,
    required this.shortcut,
    required this.formula,
    required this.example,
    required this.whenUse,
    required this.whenNotUse,
    required this.scenario,
    required this.tags,
  });

  final String id;
  final String skill;
  final String title;
  final String shortcut;
  final String formula;
  final String example;
  final String whenUse;
  final String whenNotUse;
  final String scenario;
  final List<String> tags;

  factory HandbookEntry.fromJson(Map<String, dynamic> json) {
    return HandbookEntry(
      id: json['id'] as String,
      skill: json['skill'] as String,
      title: json['title'] as String,
      shortcut: json['shortcut'] as String,
      formula: json['formula'] as String,
      example: json['example'] as String,
      whenUse: json['whenUse'] as String,
      whenNotUse: json['whenNotUse'] as String,
      scenario: json['scenario'] as String,
      tags: List<String>.from(json['tags'] as List<dynamic>),
    );
  }
}

class MetricRelationshipCase {
  const MetricRelationshipCase({
    required this.id,
    required this.title,
    required this.companyKey,
    required this.metrics,
    required this.prompt,
    required this.choices,
  });

  final String id;
  final String title;
  final String companyKey;
  final Map<String, String> metrics;
  final String prompt;
  final List<ScoredWorkChoice> choices;

  factory MetricRelationshipCase.fromJson(Map<String, dynamic> json) {
    return MetricRelationshipCase(
      id: json['id'] as String,
      title: json['title'] as String,
      companyKey: json['companyKey'] as String,
      metrics: Map<String, String>.from(json['metrics'] as Map),
      prompt: json['prompt'] as String,
      choices: (json['choices'] as List<dynamic>)
          .map(
            (item) => ScoredWorkChoice.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class ReviewDeskCase {
  const ReviewDeskCase({
    required this.id,
    required this.title,
    required this.companyKey,
    required this.artifact,
    required this.prompt,
    required this.choices,
  });

  final String id;
  final String title;
  final String companyKey;
  final String artifact;
  final String prompt;
  final List<ScoredWorkChoice> choices;

  factory ReviewDeskCase.fromJson(Map<String, dynamic> json) {
    return ReviewDeskCase(
      id: json['id'] as String,
      title: json['title'] as String,
      companyKey: json['companyKey'] as String,
      artifact: json['artifact'] as String,
      prompt: json['prompt'] as String,
      choices: (json['choices'] as List<dynamic>)
          .map(
            (item) => ScoredWorkChoice.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class AnalystStory {
  const AnalystStory({
    required this.id,
    required this.title,
    required this.companyKey,
    required this.setup,
    required this.turningPoint,
    required this.lesson,
    required this.takeaways,
  });

  final String id;
  final String title;
  final String companyKey;
  final String setup;
  final String turningPoint;
  final String lesson;
  final List<String> takeaways;

  factory AnalystStory.fromJson(Map<String, dynamic> json) {
    return AnalystStory(
      id: json['id'] as String,
      title: json['title'] as String,
      companyKey: json['companyKey'] as String,
      setup: json['setup'] as String,
      turningPoint: json['turningPoint'] as String,
      lesson: json['lesson'] as String,
      takeaways: List<String>.from(json['takeaways'] as List<dynamic>),
    );
  }
}

class JobRoleProfile {
  const JobRoleProfile({
    required this.id,
    required this.title,
    required this.description,
    required this.weights,
    required this.minProjects,
    required this.minEvidence,
  });

  final String id;
  final String title;
  final String description;
  final Map<String, double> weights;
  final int minProjects;
  final int minEvidence;

  factory JobRoleProfile.fromJson(Map<String, dynamic> json) {
    return JobRoleProfile(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      weights: Map<String, double>.from(
        (json['weights'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
      minProjects: (json['minProjects'] as num).toInt(),
      minEvidence: (json['minEvidence'] as num).toInt(),
    );
  }
}
