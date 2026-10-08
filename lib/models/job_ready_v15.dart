class FlagshipWorkday {
  const FlagshipWorkday({
    required this.id,
    required this.order,
    required this.companyKey,
    required this.companyName,
    required this.title,
    required this.role,
    required this.startTime,
    required this.endTime,
    required this.briefing,
    required this.datasetName,
    required this.previewRows,
    required this.issueOptions,
    required this.correctIssues,
    required this.toolScores,
    required this.analysisPrompt,
    required this.sqlExpectedRows,
    required this.tokenRules,
    required this.statisticsPrompt,
    required this.statisticsOptions,
    required this.statisticsExpected,
    required this.chartPrompt,
    required this.chartOptions,
    required this.chartExpected,
    required this.managerPrompt,
    required this.evidenceTerms,
    required this.impactTerms,
    required this.uncertaintyTerms,
    required this.recommendationTerms,
    required this.managerReference,
    required this.reviewFeedback,
    required this.resumeBullet,
    required this.bonusXp,
  });

  final String id;
  final int order;
  final String companyKey;
  final String companyName;
  final String title;
  final String role;
  final String startTime;
  final String endTime;
  final String briefing;
  final String datasetName;
  final List<Map<String, dynamic>> previewRows;
  final List<String> issueOptions;
  final List<String> correctIssues;
  final Map<String, int> toolScores;
  final String analysisPrompt;
  final List<Map<String, dynamic>> sqlExpectedRows;
  final Map<String, List<String>> tokenRules;
  final String statisticsPrompt;
  final List<String> statisticsOptions;
  final String statisticsExpected;
  final String chartPrompt;
  final List<String> chartOptions;
  final String chartExpected;
  final String managerPrompt;
  final List<String> evidenceTerms;
  final List<String> impactTerms;
  final List<String> uncertaintyTerms;
  final List<String> recommendationTerms;
  final String managerReference;
  final String reviewFeedback;
  final String resumeBullet;
  final int bonusXp;

  String get rewardId => 'flagship:$id';

  factory FlagshipWorkday.fromJson(Map<String, dynamic> json) {
    final rawRules = Map<String, dynamic>.from(json['tokenRules'] as Map);
    return FlagshipWorkday(
      id: json['id'] as String,
      order: (json['order'] as num).toInt(),
      companyKey: json['companyKey'] as String,
      companyName: json['companyName'] as String,
      title: json['title'] as String,
      role: json['role'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      briefing: json['briefing'] as String,
      datasetName: json['datasetName'] as String,
      previewRows: (json['previewRows'] as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      issueOptions: List<String>.from(json['issueOptions'] as List<dynamic>),
      correctIssues:
          List<String>.from(json['correctIssues'] as List<dynamic>),
      toolScores: Map<String, int>.from(json['toolScores'] as Map),
      analysisPrompt: json['analysisPrompt'] as String,
      sqlExpectedRows: (json['sqlExpectedRows'] as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      tokenRules: {
        for (final entry in rawRules.entries)
          entry.key: List<String>.from(entry.value as List<dynamic>),
      },
      statisticsPrompt: json['statisticsPrompt'] as String,
      statisticsOptions:
          List<String>.from(json['statisticsOptions'] as List<dynamic>),
      statisticsExpected: json['statisticsExpected'] as String,
      chartPrompt: json['chartPrompt'] as String,
      chartOptions: List<String>.from(json['chartOptions'] as List<dynamic>),
      chartExpected: json['chartExpected'] as String,
      managerPrompt: json['managerPrompt'] as String,
      evidenceTerms:
          List<String>.from(json['evidenceTerms'] as List<dynamic>),
      impactTerms: List<String>.from(json['impactTerms'] as List<dynamic>),
      uncertaintyTerms:
          List<String>.from(json['uncertaintyTerms'] as List<dynamic>),
      recommendationTerms:
          List<String>.from(json['recommendationTerms'] as List<dynamic>),
      managerReference: json['managerReference'] as String,
      reviewFeedback: json['reviewFeedback'] as String,
      resumeBullet: json['resumeBullet'] as String,
      bonusXp: (json['bonusXp'] as num).toInt(),
    );
  }
}

class DomainMetric {
  const DomainMetric({
    required this.name,
    required this.formula,
    required this.use,
    required this.trap,
  });

  final String name;
  final String formula;
  final String use;
  final String trap;

  factory DomainMetric.fromJson(Map<String, dynamic> json) => DomainMetric(
        name: json['name'] as String,
        formula: json['formula'] as String,
        use: json['use'] as String,
        trap: json['trap'] as String,
      );
}

class DomainPlaybook {
  const DomainPlaybook({
    required this.companyKey,
    required this.title,
    required this.operatingModel,
    required this.levers,
    required this.metrics,
  });

  final String companyKey;
  final String title;
  final String operatingModel;
  final List<String> levers;
  final List<DomainMetric> metrics;

  factory DomainPlaybook.fromJson(Map<String, dynamic> json) => DomainPlaybook(
        companyKey: json['companyKey'] as String,
        title: json['title'] as String,
        operatingModel: json['operatingModel'] as String,
        levers: List<String>.from(json['levers'] as List<dynamic>),
        metrics: (json['metrics'] as List<dynamic>)
            .map(
              (item) => DomainMetric.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      );
}

class LeadershipChoice {
  const LeadershipChoice({
    required this.text,
    required this.score,
    required this.feedback,
    required this.impact,
  });

  final String text;
  final int score;
  final String feedback;
  final Map<String, double> impact;

  factory LeadershipChoice.fromJson(Map<String, dynamic> json) =>
      LeadershipChoice(
        text: json['text'] as String,
        score: (json['score'] as num).toInt(),
        feedback: json['feedback'] as String,
        impact: Map<String, double>.from(
          (json['impact'] as Map).map(
            (key, value) => MapEntry(
              key.toString(),
              (value as num).toDouble(),
            ),
          ),
        ),
      );
}

class LeadershipCase {
  const LeadershipCase({
    required this.id,
    required this.minCareerLevel,
    required this.level,
    required this.title,
    required this.context,
    required this.choices,
  });

  final String id;
  final int minCareerLevel;
  final String level;
  final String title;
  final String context;
  final List<LeadershipChoice> choices;

  factory LeadershipCase.fromJson(Map<String, dynamic> json) => LeadershipCase(
        id: json['id'] as String,
        minCareerLevel: (json['minCareerLevel'] as num).toInt(),
        level: json['level'] as String,
        title: json['title'] as String,
        context: json['context'] as String,
        choices: (json['choices'] as List<dynamic>)
            .map(
              (item) => LeadershipChoice.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      );
}

class AdaptiveCoachScenario {
  const AdaptiveCoachScenario({
    required this.id,
    required this.title,
    required this.companyKey,
    required this.prompt,
    required this.evidenceTerms,
    required this.uncertaintyTerms,
    required this.recommendationTerms,
  });

  final String id;
  final String title;
  final String companyKey;
  final String prompt;
  final List<String> evidenceTerms;
  final List<String> uncertaintyTerms;
  final List<String> recommendationTerms;

  factory AdaptiveCoachScenario.fromJson(Map<String, dynamic> json) =>
      AdaptiveCoachScenario(
        id: json['id'] as String,
        title: json['title'] as String,
        companyKey: json['companyKey'] as String,
        prompt: json['prompt'] as String,
        evidenceTerms:
            List<String>.from(json['evidenceTerms'] as List<dynamic>),
        uncertaintyTerms:
            List<String>.from(json['uncertaintyTerms'] as List<dynamic>),
        recommendationTerms:
            List<String>.from(json['recommendationTerms'] as List<dynamic>),
      );
}
