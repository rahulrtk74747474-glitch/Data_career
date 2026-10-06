class ContentPack {
  const ContentPack({
    required this.packId,
    required this.schemaVersion,
    required this.contentVersion,
    required this.tasks,
    required this.datasets,
    required this.dialogues,
    required this.rubrics,
    required this.events,
    required this.achievements,
  });

  static const supportedSchemaVersion = 1;

  final String packId;
  final int schemaVersion;
  final int contentVersion;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> datasets;
  final List<Map<String, dynamic>> dialogues;
  final List<Map<String, dynamic>> rubrics;
  final List<Map<String, dynamic>> events;
  final List<Map<String, dynamic>> achievements;

  factory ContentPack.fromJson(Map<String, dynamic> json) {
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt();
    final contentVersion = (json['contentVersion'] as num?)?.toInt();
    final packId = json['packId'] as String? ?? '';

    if (packId.trim().isEmpty) {
      throw const FormatException('Content pack is missing packId.');
    }
    if (schemaVersion == null ||
        schemaVersion < 1 ||
        schemaVersion > supportedSchemaVersion) {
      throw FormatException(
        'Unsupported content-pack schema: $schemaVersion.',
      );
    }
    if (contentVersion == null || contentVersion < 1) {
      throw const FormatException(
        'Content pack requires contentVersion >= 1.',
      );
    }

    List<Map<String, dynamic>> maps(String key) {
      final raw = json[key] as List<dynamic>? ?? const <dynamic>[];
      return raw
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    return ContentPack(
      packId: packId,
      schemaVersion: schemaVersion,
      contentVersion: contentVersion,
      tasks: maps('tasks'),
      datasets: maps('datasets'),
      dialogues: maps('dialogues'),
      rubrics: maps('rubrics'),
      events: maps('events'),
      achievements: maps('achievements'),
    );
  }
}
