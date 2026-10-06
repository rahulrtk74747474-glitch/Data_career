class WeeklyCasePack {
  const WeeklyCasePack({
    required this.schemaVersion,
    required this.caseId,
    required this.weekKey,
    required this.title,
    required this.context,
    required this.prompt,
    required this.options,
    required this.expectedAnswer,
    required this.explanation,
  });

  static const supportedSchemaVersion = 1;

  final int schemaVersion;
  final String caseId;
  final String weekKey;
  final String title;
  final String context;
  final String prompt;
  final List<String> options;
  final String expectedAnswer;
  final String explanation;

  factory WeeklyCasePack.fromJson(Map<String, dynamic> json) {
    final schema = (json['schemaVersion'] as num?)?.toInt();
    if (schema == null || schema < 1) {
      throw const FormatException('Weekly case schema is missing.');
    }
    if (schema > supportedSchemaVersion) {
      throw FormatException(
        'Weekly case schema $schema is newer than supported.',
      );
    }
    final options = List<String>.from(
      json['options'] as List<dynamic>? ?? const [],
    );
    final expected = json['expectedAnswer'] as String? ?? '';
    if (options.length < 2 || !options.contains(expected)) {
      throw const FormatException(
        'Weekly case answer options are invalid.',
      );
    }
    return WeeklyCasePack(
      schemaVersion: schema,
      caseId: json['caseId'] as String? ?? '',
      weekKey: json['weekKey'] as String? ?? '',
      title: json['title'] as String? ?? '',
      context: json['context'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      options: options,
      expectedAnswer: expected,
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'caseId': caseId,
        'weekKey': weekKey,
        'title': title,
        'context': context,
        'prompt': prompt,
        'options': options,
        'expectedAnswer': expectedAnswer,
        'explanation': explanation,
      };
}

class WeeklyCaseLoadResult {
  const WeeklyCaseLoadResult({
    required this.pack,
    required this.source,
    this.message,
  });

  final WeeklyCasePack pack;
  final String source;
  final String? message;
}
