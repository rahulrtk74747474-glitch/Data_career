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
  ];

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
      final result = _execute(challenge.rows, command);
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

  static List<Map<String, Object?>> _execute(
    List<Map<String, dynamic>> source,
    String command,
  ) {
    final rows = [
      for (final row in source) Map<String, Object?>.from(row),
    ];
    final parts = command.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      throw const FormatException('Command is empty.');
    }

    switch (parts.first.toUpperCase()) {
      case 'LOOKUP':
        if (parts.length < 4) {
          throw const FormatException(
            'Use LOOKUP <lookupColumn> <value> <returnColumn>.',
          );
        }
        final lookupColumn = parts[1];
        final lookupValue = parts[2];
        final returnColumn = parts[3];
        final match = rows.cast<Map<String, Object?>>().where(
              (row) => row[lookupColumn]?.toString() == lookupValue,
            );
        if (match.isEmpty) return const [];
        return [
          {
            lookupColumn: match.first[lookupColumn],
            returnColumn: match.first[returnColumn],
          },
        ];
      case 'SORT':
        if (parts.length < 3) {
          throw const FormatException('Use SORT <column> ASC|DESC.');
        }
        final column = parts[1];
        final desc = parts[2].toUpperCase() == 'DESC';
        rows.sort((a, b) {
          final comparison = _compare(a[column], b[column]);
          return desc ? -comparison : comparison;
        });
        return rows;
      case 'FILTER':
        final equalsIndex = parts.indexOf('=');
        if (parts.length < 4 || equalsIndex != 2) {
          throw const FormatException(
            'Use FILTER <column> = <value>.',
          );
        }
        final column = parts[1];
        final value = parts.sublist(3).join(' ');
        return rows
            .where((row) => row[column]?.toString() == value)
            .toList();
      case 'PIVOT':
        if (parts.length < 4) {
          throw const FormatException(
            'Use PIVOT <groupColumn> SUM <valueColumn> or PIVOT <groupColumn> COUNT *.',
          );
        }
        return _pivot(
          rows,
          groupColumn: parts[1],
          aggregator: parts[2].toUpperCase(),
          valueColumn: parts[3],
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
        result.add({
          groupColumn: key,
          'count': groupRows.length,
        });
      } else if (aggregator == 'SUM') {
        final total = groupRows.fold<double>(
          0,
          (sum, row) => sum + _toDouble(row[valueColumn]),
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
        final column = parts[2];
        final replacement = parts.sublist(3).join(' ');
        for (final row in rows) {
          final value = row[column];
          if (value == null || value.toString().trim().isEmpty) {
            row[column] = replacement;
          }
        }
        return rows;
      case 'DEDUPE':
        final column = parts[2];
        final seen = <String>{};
        return rows.where((row) {
          final key = row[column]?.toString() ?? '';
          return seen.add(key);
        }).toList();
      case 'TITLE':
        final column = parts[2];
        for (final row in rows) {
          final raw = row[column]?.toString();
          if (raw == null) continue;
          row[column] = raw
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
        final column = parts[2];
        return rows
            .where((row) => _toDouble(row[column]) >= 0)
            .toList();
      case 'DATE_ISO':
        final column = parts[2];
        for (final row in rows) {
          final value = row[column]?.toString();
          if (value == null) continue;
          row[column] = _isoDate(value);
        }
        return rows;
      default:
        throw const FormatException(
          'Cleaning supports FILL, DEDUPE, TITLE, NONNEGATIVE or DATE_ISO.',
        );
    }
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
        } else if (actualValue?.toString().trim().toLowerCase() !=
            expectedValue?.toString().trim().toLowerCase()) {
          return false;
        }
      }
    }
    return true;
  }

  static int _compare(Object? a, Object? b) {
    if (a is num && b is num) return a.compareTo(b);
    return (a?.toString() ?? '').compareTo(b?.toString() ?? '');
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Object _cleanNumber(double value) =>
      value == value.roundToDouble() ? value.toInt() : value;

  static String _isoDate(String value) {
    final normalized = value.replaceAll('/', '-');
    final direct = DateTime.tryParse(normalized);
    if (direct != null) {
      return direct.toIso8601String().substring(0, 10);
    }
    final parts = value.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day)
            .toIso8601String()
            .substring(0, 10);
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
