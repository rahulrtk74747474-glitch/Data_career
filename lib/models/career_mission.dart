class CareerMission {
  const CareerMission({
    required this.id,
    required this.order,
    required this.companyChapter,
    required this.companyKey,
    required this.companyName,
    required this.managerName,
    required this.title,
    required this.briefing,
    required this.deadlineLabel,
    required this.taskIds,
    required this.bonusXp,
    required this.managerFeedback,
    required this.resumeBullet,
  });

  final String id;
  final int order;
  final int companyChapter;
  final String companyKey;
  final String companyName;
  final String managerName;
  final String title;
  final String briefing;
  final String deadlineLabel;
  final List<String> taskIds;
  final int bonusXp;
  final String managerFeedback;
  final String resumeBullet;

  String get rewardId => 'mission:$id';

  factory CareerMission.fromJson(Map<String, dynamic> json) {
    return CareerMission(
      id: json['id'] as String,
      order: (json['order'] as num).toInt(),
      companyChapter: (json['companyChapter'] as num).toInt(),
      companyKey: json['companyKey'] as String,
      companyName: json['companyName'] as String,
      managerName: json['managerName'] as String,
      title: json['title'] as String,
      briefing: json['briefing'] as String,
      deadlineLabel: json['deadlineLabel'] as String,
      taskIds: List<String>.from(json['taskIds'] as List<dynamic>),
      bonusXp: (json['bonusXp'] as num).toInt(),
      managerFeedback: json['managerFeedback'] as String,
      resumeBullet: json['resumeBullet'] as String,
    );
  }
}
