import 'analyst_task.dart';

class DailyChallengeDefinition {
  const DailyChallengeDefinition({
    required this.id,
    required this.taskId,
    required this.bonusXp,
    required this.companyKey,
    required this.minCareerLevel,
  });

  final String id;
  final String taskId;
  final int bonusXp;
  final String companyKey;
  final int minCareerLevel;

  factory DailyChallengeDefinition.fromJson(Map<String, dynamic> json) {
    return DailyChallengeDefinition(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      bonusXp: (json['bonusXp'] as num).toInt(),
      companyKey: json['companyKey'] as String,
      minCareerLevel: (json['minCareerLevel'] as num).toInt(),
    );
  }
}

class DailyChallengeSelection {
  const DailyChallengeSelection({
    required this.definition,
    required this.task,
    required this.dateKey,
  });

  final DailyChallengeDefinition definition;
  final AnalystTask task;
  final String dateKey;
}
