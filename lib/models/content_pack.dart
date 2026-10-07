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

  static const supportedSchemaVersion = 2;

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
      final raw = json[key];
      if (schemaVersion >= 2 && raw is! List) {
        throw FormatException('Content pack field $key must be an array.');
      }
      if (raw == null) return <Map<String, dynamic>>[];
      if (raw is! List) {
        throw FormatException('Content pack field $key must be an array.');
      }
      return raw.map((item) {
        if (item is! Map) {
          throw FormatException(
            'Content pack field $key must contain objects only.',
          );
        }
        return Map<String, dynamic>.from(item);
      }).toList();
    }

    final pack = ContentPack(
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
    pack.validate();
    return pack;
  }

  void validate() {
    _uniqueIds(tasks, 'task');
    _uniqueIds(datasets, 'dataset');
    _uniqueIds(dialogues, 'dialogue');
    _uniqueIds(rubrics, 'rubric');
    _uniqueIds(events, 'event');
    _uniqueIds(achievements, 'achievement');

    for (final task in tasks) {
      _require(
        task,
        const [
          'id',
          'title',
          'skillKey',
          'difficulty',
          'companyKey',
          'answerType',
        ],
        'task',
      );
    }
    for (final dataset in datasets) {
      _require(dataset, const ['id', 'name'], 'dataset');
    }
    for (final dialogue in dialogues) {
      _require(dialogue, const ['id', 'triggerKey'], 'dialogue');
    }
    for (final rubric in rubrics) {
      _require(rubric, const ['id', 'kind'], 'rubric');
    }
    for (final event in events) {
      _require(event, const ['id', 'eventType'], 'event');
    }
    for (final achievement in achievements) {
      _require(
        achievement,
        const ['id', 'title', 'description', 'rule'],
        'achievement',
      );
    }

    if (schemaVersion < 2) return;

    final datasetIds = datasets.map((row) => row['id'] as String).toSet();
    final rubricIds = rubrics.map((row) => row['id'] as String).toSet();

    for (final dataset in datasets) {
      _require(dataset, const ['columns', 'rows'], 'dataset');
      if (dataset['columns'] is! List || dataset['rows'] is! List) {
        throw FormatException(
          'dataset ${dataset['id']} requires array columns and rows.',
        );
      }
    }

    for (final rubric in rubrics) {
      _require(rubric, const ['criteria'], 'rubric');
      final criteria = rubric['criteria'];
      if (criteria is! List || criteria.isEmpty) {
        throw FormatException(
          'rubric ${rubric['id']} requires at least one criterion.',
        );
      }
      num totalWeight = 0;
      for (final criterion in criteria) {
        if (criterion is! Map) {
          throw FormatException(
            'rubric ${rubric['id']} criteria must be objects.',
          );
        }
        final row = Map<String, dynamic>.from(criterion);
        _require(row, const ['key', 'weight'], 'rubric criterion');
        final weight = row['weight'];
        if (weight is! num || weight <= 0) {
          throw FormatException(
            'rubric ${rubric['id']} criterion weights must be positive.',
          );
        }
        totalWeight += weight;
      }
      if (totalWeight != 100) {
        throw FormatException(
          'rubric ${rubric['id']} criterion weights must total 100.',
        );
      }
    }

    for (final dialogue in dialogues) {
      _require(dialogue, const ['speaker', 'text'], 'dialogue');
    }

    for (final event in events) {
      _require(event, const ['title', 'description', 'decision'], 'event');
    }

    for (final task in tasks) {
      _require(
        task,
        const [
          'context',
          'prompt',
          'datasetId',
          'rubricId',
          'hints',
        ],
        'task',
      );

      final hints = task['hints'];
      if (hints is! List ||
          hints.length != 3 ||
          hints.any((hint) => hint.toString().trim().isEmpty)) {
        throw FormatException(
          'task ${task['id']} requires exactly three non-empty hints.',
        );
      }

      final datasetId = task['datasetId'] as String;
      if (!datasetIds.contains(datasetId)) {
        throw FormatException(
          'task ${task['id']} references missing dataset $datasetId.',
        );
      }

      final rubricId = task['rubricId'] as String;
      if (!rubricIds.contains(rubricId)) {
        throw FormatException(
          'task ${task['id']} references missing rubric $rubricId.',
        );
      }

      final hasExpectedAnswer =
          _hasValue(task['expectedAnswer']) ||
          _hasListValue(task['expectedRows']) ||
          _hasListValue(task['expectedSelections']);
      if (!hasExpectedAnswer) {
        throw FormatException(
          'task ${task['id']} requires an expected answer or result.',
        );
      }
    }
  }

  static bool _hasValue(dynamic value) {
    return value != null && value.toString().trim().isNotEmpty;
  }

  static bool _hasListValue(dynamic value) {
    return value is List && value.isNotEmpty;
  }

  static void _uniqueIds(
    List<Map<String, dynamic>> rows,
    String label,
  ) {
    final seen = <String>{};
    for (final row in rows) {
      final raw = row['id'];
      if (raw == null || raw.toString().trim().isEmpty) {
        throw FormatException('$label is missing required field id.');
      }
      final id = raw.toString();
      if (!seen.add(id)) {
        throw FormatException('Duplicate $label id: $id.');
      }
    }
  }

  static void _require(
    Map<String, dynamic> row,
    List<String> keys,
    String label,
  ) {
    for (final key in keys) {
      final value = row[key];
      if (value == null || value.toString().trim().isEmpty) {
        throw FormatException('$label is missing required field $key.');
      }
    }
  }
}
