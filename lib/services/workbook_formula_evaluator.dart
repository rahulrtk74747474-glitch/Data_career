/// A deliberately limited, offline spreadsheet arithmetic evaluator.
///
/// Unlike a formula string matcher, this computes results on source rows AND
/// altered rows; it is not Microsoft Excel or a full spreadsheet engine.
class WorkbookFormulaEvaluator {
  const WorkbookFormulaEvaluator._();

  static double evaluate(String formula, Map<String, dynamic> row) {
    final normalized = formula.trim();
    final expression = normalized.toUpperCase().startsWith('FORMULA ')
        ? normalized.substring(8).trim()
        : normalized;
    if (!expression.startsWith('=')) {
      throw const FormatException('Start a workbook formula with =.');
    }
    return _FormulaParser(expression.substring(1), row).parse();
  }

  static bool equivalent({
    required String candidate,
    required String reference,
    required List<Map<String, dynamic>> rows,
  }) {
    if (rows.isEmpty) return false;
    try {
      for (final row in rows) {
        if (!_close(evaluate(candidate, row), evaluate(reference, row))) {
          return false;
        }
        final altered = Map<String, dynamic>.from(row);
        for (final key in row.keys) {
          if (key == 'row') continue;
          final original = row[key];
          if (original is num) {
            altered[key] = original.toDouble() * 1.13 + 1.37;
            if (!_close(evaluate(candidate, altered), evaluate(reference, altered))) {
              return false;
            }
            altered[key] = original;
          }
        }
      }
      return true;
    } on FormatException {
      return false;
    }
  }

  static bool _close(double a, double b) =>
      a.isFinite && b.isFinite &&
      (a - b).abs() <= 0.000001 * (1 + b.abs());
}

class _FormulaParser {
  _FormulaParser(String text, this.row)
      : input = text.replaceAll(r'$', '').replaceAll(' ', '');

  final String input;
  final Map<String, dynamic> row;
  int position = 0;

  double parse() {
    final result = _expression();
    if (position != input.length) {
      throw const FormatException('Unexpected trailing formula characters.');
    }
    return result;
  }

  double _expression() {
    var value = _term();
    while (true) {
      if (_eat('+')) {
        value += _term();
      } else if (_eat('-')) {
        value -= _term();
      } else {
        return value;
      }
    }
  }

  double _term() {
    var value = _factor();
    while (true) {
      if (_eat('*')) {
        value *= _factor();
      } else if (_eat('/')) {
        final denominator = _factor();
        if (denominator == 0) {
          throw const FormatException('Formula divides by zero.');
        }
        value /= denominator;
      } else {
        return value;
      }
    }
  }

  double _factor() {
    if (_eat('+')) return _factor();
    if (_eat('-')) return -_factor();
    if (_eat('(')) {
      final result = _expression();
      if (!_eat(')')) throw const FormatException('Missing closing parenthesis.');
      return result;
    }
    if (position >= input.length) {
      throw const FormatException('Formula ended before a value.');
    }
    final suffix = input.substring(position);
    final numeric = RegExp(r'^\d+(?:\.\d+)?').firstMatch(suffix);
    if (numeric != null) {
      position += numeric.group(0)!.length;
      return double.parse(numeric.group(0)!);
    }
    final identifier = RegExp(r'^[A-Za-z]+\d*').firstMatch(suffix);
    if (identifier == null) {
      throw FormatException('Unsupported formula token near $suffix.');
    }
    final id = identifier.group(0)!.toUpperCase();
    position += id.length;
    if (_eat('(')) {
      final args = <double>[];
      if (!_eat(')')) {
        do {
          args.add(_expression());
        } while (_eat(','));
        if (!_eat(')')) {
          throw const FormatException('Missing function closing parenthesis.');
        }
      }
      if (args.isEmpty) throw const FormatException('Function needs values.');
      switch (id) {
        case 'SUM': return args.reduce((a, b) => a + b);
        case 'AVERAGE': return args.reduce((a, b) => a + b) / args.length;
        case 'MIN': return args.reduce((a, b) => a < b ? a : b);
        case 'MAX': return args.reduce((a, b) => a > b ? a : b);
        default: throw FormatException('Unsupported function $id.');
      }
    }
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(id);
    if (match == null) throw FormatException('Unsupported identifier $id.');
    final rowNumber = int.parse(match.group(2)!);
    final expectedRow = row['row'] is num
        ? (row['row'] as num).toInt()
        : 2;
    if (rowNumber != expectedRow) {
      throw FormatException('Cell $id is outside the current data row.');
    }
    var columnIndex = 0;
    for (final char in match.group(1)!.codeUnits) {
      columnIndex = columnIndex * 26 + char - 64;
    }
    columnIndex -= 1;
    if (columnIndex < 0 || columnIndex >= row.length) {
      throw FormatException('Cell $id is outside the workbook.');
    }
    final value = row.values.elementAt(columnIndex);
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
    throw FormatException('Cell $id does not contain a numeric value.');
  }

  bool _eat(String token) {
    if (input.startsWith(token, position)) {
      position += token.length;
      return true;
    }
    return false;
  }
}
