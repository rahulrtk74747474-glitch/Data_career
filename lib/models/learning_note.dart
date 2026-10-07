class LearningNote {
  const LearningNote({
    required this.id,
    required this.title,
    required this.skillKey,
    required this.shortcut,
    required this.detail,
    required this.source,
    this.manualIndex,
  });

  final String id;
  final String title;
  final String skillKey;
  final String shortcut;
  final String detail;
  final String source;
  final int? manualIndex;
}
