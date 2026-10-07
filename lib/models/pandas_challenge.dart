class PandasChallenge {
  const PandasChallenge({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.context,
    required this.datasetName,
    required this.rows,
    required this.prompt,
    required this.requiredFragments,
    required this.operation,
    required this.expectedRows,
    required this.hints,
    required this.explanation,
    required this.xp,
  });

  final String id;
  final String title;
  final String difficulty;
  final String context;
  final String datasetName;
  final List<Map<String, Object?>> rows;
  final String prompt;
  final List<String> requiredFragments;
  final Map<String, dynamic> operation;
  final List<Map<String, dynamic>> expectedRows;
  final List<String> hints;
  final String explanation;
  final int xp;

  String get solutionText {
    final type = operation['type'] as String? ?? '';
    switch (type) {
      case 'filter_equals':
        final column = operation['column'];
        final value = operation['value'];
        final selected = List<String>.from(operation['selectColumns'] as List);
        return "df[df['$column'] == ${_literal(value)}][${selected.map((e) => "'$e'").toList()}]\n\n$explanation";
      case 'fillna':
        final column = operation['column'];
        final value = operation['value'];
        return "df['$column'] = df['$column'].fillna(${_literal(value)})\n\n$explanation";
      case 'group_sum':
        final groupBy = operation['groupBy'];
        final valueColumn = operation['valueColumn'];
        return "df.groupby('$groupBy')['$valueColumn'].sum()\n\n$explanation";
      case 'sort_head':
        final sortBy = operation['sortBy'];
        final descending = operation['descending'] == true;
        final head = operation['head'];
        return "df.sort_values('$sortBy', ascending=${!descending}).head($head)\n\n$explanation";
      case 'assign_ratio':
        final numerator = operation['numerator'];
        final denominator = operation['denominator'];
        final newColumn = operation['newColumn'];
        final multiplier = operation['multiplier'] ?? 1;
        return "df['$newColumn'] = (df['$numerator'] / df['$denominator'] * $multiplier).round(1)\n\n$explanation";
      case 'filter_group_sum':
        final filterColumn = operation['filterColumn'];
        final filterValue = operation['filterValue'];
        final groupBy = operation['groupBy'];
        final valueColumn = operation['valueColumn'];
        return "df[df['$filterColumn'] == ${_literal(filterValue)}].groupby('$groupBy')['$valueColumn'].sum()\n\n$explanation";
      default:
        return 'Follow the requested Pandas operations in order.\n\n$explanation';
    }
  }

  static String _literal(Object? value) =>
      value is String ? "'$value'" : value.toString();

  factory PandasChallenge.fromJson(Map<String, dynamic> json) {
    return PandasChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      difficulty: json['difficulty'] as String,
      context: json['context'] as String,
      datasetName: json['datasetName'] as String,
      rows: (json['rows'] as List<dynamic>)
          .map((row) => Map<String, Object?>.from(row as Map))
          .toList(),
      prompt: json['prompt'] as String,
      requiredFragments:
          List<String>.from(json['requiredFragments'] as List<dynamic>),
      operation: Map<String, dynamic>.from(json['operation'] as Map),
      expectedRows: (json['expectedRows'] as List<dynamic>)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      hints: List<String>.from(json['hints'] as List<dynamic>),
      explanation: json['explanation'] as String,
      xp: json['xp'] as int,
    );
  }
}
