import '../models/pandas_challenge.dart';
import 'sql_result_grader.dart';

class PandasRunResult {
  const PandasRunResult({
    required this.isCorrect,
    required this.feedback,
    required this.rows,
  });

  final bool isCorrect;
  final String feedback;
  final List<Map<String, Object?>> rows;
}

class PandasSimulator {
  const PandasSimulator._();

  static PandasRunResult run(PandasChallenge challenge, String rawCode) {
    if (rawCode.trim().isEmpty) {
      return const PandasRunResult(
        isCorrect: false,
        feedback: 'Write a Pandas expression before running it.',
        rows: [],
      );
    }

    final normalized = _normalize(rawCode);
    final missing = challenge.requiredFragments
        .where((fragment) => !normalized.contains(_normalize(fragment)))
        .toList();

    if (missing.isNotEmpty) {
      return PandasRunResult(
        isCorrect: false,
        feedback:
            'The expression is missing part of the requested Pandas workflow. Check filtering, selected columns, grouping, sorting, or assignment.',
        rows: const [],
      );
    }

    final rows = _execute(challenge);
    final grade = SqlResultGrader.grade(
      actualRows: rows,
      expectedRows: challenge.expectedRows,
    );

    return PandasRunResult(
      isCorrect: grade.isCorrect,
      feedback: grade.isCorrect
          ? 'Correct. The simulated dataframe output matches the requested result.'
          : 'Your expression shape looks close, but the dataframe result is not the expected one.',
      rows: rows,
    );
  }

  static List<Map<String, Object?>> _execute(PandasChallenge challenge) {
    final op = challenge.operation;
    final type = op['type'] as String;
    final source = challenge.rows
        .map<Map<String, Object?>>(
          (row) => Map<String, Object?>.from(row),
        )
        .toList();

    switch (type) {
      case 'filter_equals':
        final column = op['column'] as String;
        final value = op['value'];
        final selected = List<String>.from(op['selectColumns'] as List);
        return source
            .where((row) => row[column] == value)
            .map((row) => _select(row, selected))
            .toList();

      case 'fillna':
        final column = op['column'] as String;
        final value = op['value'];
        return source.map((row) {
          final copy = Map<String, Object?>.from(row);
          final current = copy[column];
          if (current == null || current.toString().isEmpty) {
            copy[column] = value;
          }
          return copy;
        }).toList();

      case 'group_sum':
        final groupBy = op['groupBy'] as String;
        final valueColumn = op['valueColumn'] as String;
        final outputColumn = op['outputColumn'] as String;
        final groups = <Object?, double>{};
        for (final row in source) {
          final key = row[groupBy];
          groups[key] =
              (groups[key] ?? 0) + (row[valueColumn] as num).toDouble();
        }
        return groups.entries
            .map(
              (entry) => <String, Object?>{
                groupBy: entry.key,
                outputColumn: _compactNumber(entry.value),
              },
            )
            .toList();

      case 'sort_head':
        final sortBy = op['sortBy'] as String;
        final descending = op['descending'] as bool;
        final head = (op['head'] as num).toInt();
        final selected = List<String>.from(op['selectColumns'] as List);
        source.sort((a, b) {
          final aValue = a[sortBy] as num;
          final bValue = b[sortBy] as num;
          final compared = aValue.compareTo(bValue);
          return descending ? -compared : compared;
        });
        return source
            .take(head)
            .map((row) => _select(row, selected))
            .toList();

      case 'assign_ratio':
        final numerator = op['numerator'] as String;
        final denominator = op['denominator'] as String;
        final newColumn = op['newColumn'] as String;
        final multiplier = (op['multiplier'] as num?)?.toDouble() ?? 1;
        final precision = (op['precision'] as num?)?.toInt() ?? 1;
        final factor = _pow10(precision);
        return source.map((row) {
          final copy = Map<String, Object?>.from(row);
          final denominatorValue = (row[denominator] as num).toDouble();
          final ratio = denominatorValue == 0
              ? 0.0
              : (row[numerator] as num).toDouble() /
                  denominatorValue *
                  multiplier;
          copy[newColumn] = (ratio * factor).round() / factor;
          return copy;
        }).toList();

      case 'filter_group_sum':
        final filterColumn = op['filterColumn'] as String;
        final filterValue = op['filterValue'];
        final groupBy = op['groupBy'] as String;
        final valueColumn = op['valueColumn'] as String;
        final outputColumn = op['outputColumn'] as String;
        final groups = <Object?, double>{};
        for (final row in source.where(
          (item) => item[filterColumn] == filterValue,
        )) {
          final key = row[groupBy];
          groups[key] =
              (groups[key] ?? 0) + (row[valueColumn] as num).toDouble();
        }
        return groups.entries
            .map(
              (entry) => <String, Object?>{
                groupBy: entry.key,
                outputColumn: _compactNumber(entry.value),
              },
            )
            .toList();

      default:
        return const [];
    }
  }

  static Map<String, Object?> _select(
    Map<String, Object?> row,
    List<String> columns,
  ) {
    return <String, Object?>{
      for (final column in columns) column: row[column],
    };
  }

  static Object _compactNumber(double value) {
    return value == value.roundToDouble() ? value.toInt() : value;
  }

  static double _pow10(int precision) {
    var result = 1.0;
    for (var index = 0; index < precision; index++) {
      result *= 10;
    }
    return result;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('"', "'")
        .replaceAll(RegExp(r'\s+'), '');
  }
}
