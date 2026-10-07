import '../models/spreadsheet_challenge.dart';
import 'sql_result_grader.dart';

class SpreadsheetRunResult {
  const SpreadsheetRunResult({
    required this.isCorrect,
    required this.feedback,
    required this.rows,
  });

  final bool isCorrect;
  final String feedback;
  final List<Map<String, Object?>> rows;
}

class SpreadsheetSimulator {
  const SpreadsheetSimulator._();

  static const shortcuts = <String>[
    'FORMULA ',
    'LOOKUP ',
    'SORT ',
    'FILTER ',
    'PIVOT ',
    'CLEAN FILL ',
    'CLEAN DEDUPE ',
    'CLEAN TITLE ',
    'CLEAN NONNEGATIVE ',
    'CLEAN DATE_ISO ',
    'CLEAN OUTLIERS_IQR ',
  ];

  static const commandHelp = <String, String>{
    'FORMULA': 'FORMULA =B2*(1-C2)',
    'LOOKUP': 'LOOKUP <lookupColumn> <value> <returnColumn>',
    'SORT': 'SORT <column> ASC|DESC',
    'FILTER': 'FILTER <column> = <value>',
    'PIVOT': 'PIVOT <groupColumn> SUM <valueColumn> or COUNT *',
    'CLEAN FILL': 'CLEAN FILL <column> <replacement>',
    'CLEAN DEDUPE': 'CLEAN DEDUPE <businessKey>',
    'CLEAN TITLE': 'CLEAN TITLE <column>',
    'CLEAN NONNEGATIVE': 'CLEAN NONNEGATIVE <numericColumn>',
    'CLEAN DATE_ISO': 'CLEAN DATE_ISO <dateColumn>',
    'CLEAN OUTLIERS_IQR': 'CLEAN OUTLIERS_IQR <numericColumn>',
  };

  static SpreadsheetRunResult run(
    SpreadsheetChallenge challenge,
    String rawCommand,
  ) {
    final command = rawCommand.trim();
    if (command.isEmpty) {
      return const SpreadsheetRunResult(
        isCorrect: false,
        feedback: 'Enter a workbook command first.',
        rows: [],
      );
    }

    if (challenge.isFormula) {
      final correct = _normalize(command) ==
          _normalize(challenge.expectedCommand);
      return SpreadsheetRunResult(
        isCorrect: correct,
        feedback: correct
            ? 'Correct. The formula matches the requested calculation.'
            : 'Not yet. Check cell references, operators and formula order.',
        rows: const [],
      );
    }

    try {
      final result = executeRows(challenge.rows, command);
      final orderMatters = command.toUpperCase().startsWith('SORT ');
      final correct = orderMatters
          ? _orderedRowsEqual(result, challenge.expectedRows)
          : SqlResultGrader.grade(
              actualRows: result,
              expectedRows: challenge.expectedRows,
            ).isCorrect;
      return SpreadsheetRunResult(
        isCorrect: correct,
        feedback: correct
            ? 'Correct. The workbook output matches the expected result.'
            : orderMatters
                ? 'The rows are present, but the requested sort order is not correct yet.'
                : 'The command ran, but the resulting rows do not yet match the requested output.',
        rows: result,
      );
    } on FormatException catch (error) {
      return SpreadsheetRunResult(
        isCorrect: false,
        feedback: 'Workbook command error: ${error.message}',
        rows: const [],
      );
    } catch (_) {
      return const SpreadsheetRunResult(
        isCorrect: false,
        feedback:
            'The workbook action could not run. Check the command and column names.',
        rows: [],
      );
    }
  }

  static List<Map<String, Object?>> executeRows(
    List<Map<String, dynamic>> source,
    String command,
  ) {
    final rows = [
      for (final row in source) Map<String, Object?>.from(row),
    ];
    final parts = command.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      throw const FormatException('Command is empty.');
    }

    switch (parts.first.toUpperCase()) {
      case 'LOOKUP':
        if (parts.length != 4) {
          throw const FormatException(
            'Use LOOKUP <lookupColumn> <value> <returnColumn>.',
          );
        }
        final lookupColumn = _resolveColumn(rows, parts[1]);
        final returnColumn = _resolveColumn(rows, parts[3]);
        final lookupValue = parts[2];
        final matches = rows.where(
          (row) => _textEquals(row[lookupColumn], lookupValue),
        );
        if (matches.isEmpty) return const [];
        return [
          {
            lookupColumn: matches.first[lookupColumn],
            returnColumn: matches.first[returnColumn],
          },
        ];

      case 'SORT':
        if (parts.length != 3) {
          throw const FormatException('Use SORT <column> ASC|DESC.');
        }
        final column = _resolveColumn(rows, parts[1]);
        final direction = parts[2].toUpperCase();
        if (direction != 'ASC' && direction != 'DESC') {
          throw const FormatException(
            'Sort direction must be ASC or DESC.',
          );
        }
        final desc = direction == 'DESC';
        rows.sort((a, b) {
          final comparison = _compare(a[column], b[column]);
          return desc ? -comparison : comparison;
        });
        return rows;

      case 'FILTER':
        if (parts.length < 4 || parts[2] != '=') {
          throw const FormatException(
            'Use FILTER <column> = <value>.',
          );
        }
        final column = _resolveColumn(rows, parts[1]);
        final value = parts.sublist(3).join(' ');
        return rows
            .where((row) => _textEquals(row[column], value))
            .toList();

      case 'PIVOT':
        if (parts.length != 4) {
          throw const FormatException(
            'Use PIVOT <groupColumn> SUM <valueColumn> or PIVOT <groupColumn> COUNT *.',
          );
        }
        final groupColumn = _resolveColumn(rows, parts[1]);
        final aggregator = parts[2].toUpperCase();
        final requestedValueColumn = parts[3];
        final valueColumn = aggregator == 'COUNT' && requestedValueColumn == '*'
            ? '*'
            : _resolveColumn(rows, requestedValueColumn);
        return _pivot(
          rows,
          groupColumn: groupColumn,
          aggregator: aggregator,
          valueColumn: valueColumn,
        );

      case 'CLEAN':
        if (parts.length < 3) {
          throw const FormatException('CLEAN needs an operation.');
        }
        return _clean(rows, parts);

      default:
        throw const FormatException(
          'Use FORMULA, LOOKUP, SORT, FILTER, PIVOT or CLEAN.',
        );
    }
  }

  static List<Map<String, Object?>> _pivot(
    List<Map<String, Object?>> rows, {
    required String groupColumn,
    required String aggregator,
    required String valueColumn,
  }) {
    final groups = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      final key = row[groupColumn]?.toString() ?? 'null';
      groups.putIfAbsent(key, () => []).add(row);
    }

    final result = <Map<String, Object?>>[];
    final keys = groups.keys.toList()..sort();
    for (final key in keys) {
      final groupRows = groups[key]!;
      if (aggregator == 'COUNT') {
        if (valueColumn != '*') {
          throw const FormatException('Use COUNT * to count pivot rows.');
        }
        result.add({
          groupColumn: key,
          'count': groupRows.length,
        });
      } else if (aggregator == 'SUM') {
        final total = groupRows.fold<double>(
          0,
          (sum, row) => sum + _requiredDouble(row[valueColumn], valueColumn),
        );
        result.add({
          groupColumn: key,
          'sum_$valueColumn': _cleanNumber(total),
        });
      } else {
        throw const FormatException('Pivot supports SUM or COUNT.');
      }
    }
    return result;
  }

  static List<Map<String, Object?>> _clean(
    List<Map<String, Object?>> rows,
    List<String> parts,
  ) {
    final operation = parts[1].toUpperCase();
    switch (operation) {
      case 'FILL':
        if (parts.length < 4) {
          throw const FormatException(
            'Use CLEAN FILL <column> <replacement>.',
          );
        }
        final column = _resolveColumn(rows, parts[2]);
        final replacement = parts.sublist(3).join(' ');
        for (final row in rows) {
          final value = row[column];
          if (value == null || value.toString().trim().isEmpty) {
            row[column] = replacement;
          }
        }
        return rows;

      case 'DEDUPE':
        if (parts.length != 3) {
          throw const FormatException('Use CLEAN DEDUPE <businessKey>.');
        }
        final column = _resolveColumn(rows, parts[2]);
        final seen = <String>{};
        return rows.where((row) {
          final key = row[column]?.toString() ?? '<null>';
          return seen.add(key);
        }).toList();

      case 'TITLE':
        if (parts.length != 3) {
          throw const FormatException('Use CLEAN TITLE <column>.');
        }
        final column = _resolveColumn(rows, parts[2]);
        for (final row in rows) {
          final raw = row[column]?.toString();
          if (raw == null) continue;
          row[column] = raw
              .trim()
              .toLowerCase()
              .split(RegExp(r'\s+'))
              .map(
                (word) => word.isEmpty
                    ? word
                    : '${word[0].toUpperCase()}${word.substring(1)}',
              )
              .join(' ');
        }
        return rows;

      case 'NONNEGATIVE':
        if (parts.length != 3) {
          throw const FormatException(
            'Use CLEAN NONNEGATIVE <numericColumn>.',
          );
        }
        final column = _resolveColumn(rows, parts[2]);
        return rows.where((row) {
          return _requiredDouble(row[column], column) >= 0;
        }).toList();

      case 'DATE_ISO':
        if (parts.length != 3) {
          throw const FormatException('Use CLEAN DATE_ISO <dateColumn>.');
        }
        final column = _resolveColumn(rows, parts[2]);
        for (final row in rows) {
          final value = row[column]?.toString();
          if (value == null || value.trim().isEmpty) continue;
          row[column] = _isoDate(value);
        }
        return rows;

      case 'OUTLIERS_IQR':
        if (parts.length != 3) {
          throw const FormatException(
            'Use CLEAN OUTLIERS_IQR <numericColumn>.',
          );
        }
        final column = _resolveColumn(rows, parts[2]);
        return _removeIqrOutliers(rows, column);

      default:
        throw const FormatException(
          'Cleaning supports FILL, DEDUPE, TITLE, NONNEGATIVE, DATE_ISO or OUTLIERS_IQR.',
        );
    }
  }

  static List<Map<String, Object?>> _removeIqrOutliers(
    List<Map<String, Object?>> rows,
    String column,
  ) {
    final values = <double>[];
    for (final row in rows) {
      final raw = row[column];
      if (raw == null || raw.toString().trim().isEmpty) continue;
      values.add(_requiredDouble(raw, column));
    }
    if (values.length < 4) {
      throw const FormatException(
        'IQR outlier cleaning needs at least 4 numeric values.',
      );
    }

    values.sort();
    final q1 = _percentile(values, 0.25);
    final q3 = _percentile(values, 0.75);
    final iqr = q3 - q1;
    final lower = q1 - (1.5 * iqr);
    final upper = q3 + (1.5 * iqr);

    return rows.where((row) {
      final raw = row[column];
      if (raw == null || raw.toString().trim().isEmpty) return true;
      final value = _requiredDouble(raw, column);
      return value >= lower && value <= upper;
    }).toList();
  }

  static double _percentile(List<double> sorted, double p) {
    final position = (sorted.length - 1) * p;
    final lowerIndex = position.floor();
    final upperIndex = position.ceil();
    if (lowerIndex == upperIndex) return sorted[lowerIndex];
    final weight = position - lowerIndex;
    return sorted[lowerIndex] * (1 - weight) + sorted[upperIndex] * weight;
  }

  static String _resolveColumn(
    List<Map<String, Object?>> rows,
    String requested,
  ) {
    if (rows.isEmpty) {
      throw const FormatException('The workbook has no rows.');
    }
    final normalized = requested.trim().toLowerCase();
    for (final key in rows.first.keys) {
      if (key.toLowerCase() == normalized) return key;
    }
    throw FormatException(
      'Column "$requested" does not exist in this workbook.',
    );
  }

  static bool _textEquals(Object? left, Object? right) {
    return (left?.toString().trim().toLowerCase() ?? '') ==
        (right?.toString().trim().toLowerCase() ?? '');
  }

  static bool _orderedRowsEqual(
    List<Map<String, Object?>> actual,
    List<Map<String, dynamic>> expected,
  ) {
    if (actual.length != expected.length) return false;
    for (var index = 0; index < actual.length; index++) {
      final a = actual[index];
      final e = expected[index];
      if (a.length != e.length) return false;
      for (final entry in e.entries) {
        final actualValue = a[entry.key];
        final expectedValue = entry.value;
        if (actualValue is num && expectedValue is num) {
          if ((actualValue.toDouble() - expectedValue.toDouble()).abs() >
              0.000001) {
            return false;
          }
        } else if (!_textEquals(actualValue, expectedValue)) {
          return false;
        }
      }
    }
    return true;
  }

  static int _compare(Object? a, Object? b) {
    if (a is num && b is num) return a.compareTo(b);
    return (a?.toString().toLowerCase() ?? '')
        .compareTo(b?.toString().toLowerCase() ?? '');
  }

  static double _requiredDouble(Object? value, String column) {
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
    throw FormatException(
      'Column "$column" must contain numeric values for this action.',
    );
  }

  static Object _cleanNumber(double value) =>
      value == value.roundToDouble() ? value.toInt() : value;

  static String _isoDate(String value) {
    final trimmed = value.trim();
    final normalized = trimmed.replaceAll('/', '-');
    final direct = DateTime.tryParse(normalized);
    if (direct != null) {
      return direct.toIso8601String().substring(0, 10);
    }
    final parts = trimmed.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        final parsed = DateTime(year, month, day);
        if (parsed.year == year &&
            parsed.month == month &&
            parsed.day == day) {
          return parsed.toIso8601String().substring(0, 10);
        }
      }
    }
    throw FormatException('Could not parse date $value.');
  }

  static String _normalize(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(r'$', '')
        .toUpperCase();
  }
}
