class BackupSnapshot {
  const BackupSnapshot({
    required this.schemaVersion,
    required this.createdAt,
    required this.appVersion,
    required this.progress,
    required this.reminderSettings,
    required this.tables,
  });

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final DateTime createdAt;
  final String appVersion;
  final Map<String, dynamic> progress;
  final Map<String, dynamic> reminderSettings;
  final Map<String, List<Map<String, dynamic>>> tables;

  Map<String, dynamic> toJson() => {
        'format': 'dataquest-backup',
        'schemaVersion': schemaVersion,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'appVersion': appVersion,
        'progress': progress,
        'reminderSettings': reminderSettings,
        'tables': tables,
      };

  factory BackupSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['format'] != 'dataquest-backup') {
      throw const FormatException('Not a DataQuest backup.');
    }
    final schema = (json['schemaVersion'] as num?)?.toInt();
    if (schema == null || schema < 1) {
      throw const FormatException('Backup schema version is missing.');
    }
    if (schema > currentSchemaVersion) {
      throw FormatException(
        'Backup schema $schema is newer than this app supports.',
      );
    }

    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    if (createdAt == null) {
      throw const FormatException('Backup creation time is invalid.');
    }

    final rawTables = json['tables'];
    if (rawTables is! Map) {
      throw const FormatException('Backup tables are invalid.');
    }

    final tables = <String, List<Map<String, dynamic>>>{};
    for (final entry in rawTables.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! List) {
        throw const FormatException('Backup table structure is invalid.');
      }
      tables[key] = [
        for (final row in value)
          if (row is Map)
            Map<String, dynamic>.from(row)
          else
            throw const FormatException('Backup contains an invalid row.'),
      ];
    }

    return BackupSnapshot(
      schemaVersion: schema,
      createdAt: createdAt.toUtc(),
      appVersion: json['appVersion'] as String? ?? 'unknown',
      progress: Map<String, dynamic>.from(
        json['progress'] as Map? ?? const {},
      ),
      reminderSettings: Map<String, dynamic>.from(
        json['reminderSettings'] as Map? ?? const {},
      ),
      tables: tables,
    );
  }
}
