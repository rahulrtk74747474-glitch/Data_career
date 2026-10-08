// ignore_for_file: prefer_interpolation_to_compose_strings
/// Offline evaluator for a deliberately documented spreadsheet subset.
/// This is NOT Excel; macros, external links and unsupported functions fail.
class WorkbookFormulaEvaluator {
  const WorkbookFormulaEvaluator._();

  static double evaluate(String raw, List<Map<String, dynamic>> rows) {
    final source = raw.trim().replaceFirst(
      RegExp(r'^FORMULA\s+', caseSensitive: false), '',
    ).trim();
    if (!source.startsWith('=')) {
      throw const FormatException('Start with =, for example FORMULA =B2-C2.');
    }
    final value = _FormulaParser(source.substring(1), rows).parse();
    if (!value.isFinite) throw const FormatException('Formula is not finite.');
    return value;
  }

  /// Evaluate on the original and on altered workbooks. Accept equivalent
  /// equations, but not literal totals memorized from one example.
  static bool equivalent(
    String candidate,
    String expected,
    List<Map<String, dynamic>> original,
  ) {
    for (var variant = 0; variant < 4; variant++) {
      final rows = [
        for (final row in original)
          {
            for (final entry in row.entries)
              entry.key: _variant(entry.key, entry.value, variant),
          },
      ];
      final actual = evaluate(candidate, rows);
      final reference = evaluate(expected, rows);
      if ((actual - reference).abs() > 0.000001 * (1 + reference.abs())) {
        return false;
      }
    }
    return true;
  }

  static Object? _variant(String key, Object? value, int variant) {
    if (variant == 0 || value is! num || key.toLowerCase() == 'row') {
      return value;
    }
    final n = value.toDouble();
    if (n >= 0 && n <= 1 &&
        (key.toLowerCase().contains('rate') ||
            key.toLowerCase().contains('percent'))) {
      return (n * (1 + variant * 0.13)).clamp(0.0, 0.95).toDouble();
    }
    return n + variant * (17 + key.length);
  }
}

class _FormulaParser {
  _FormulaParser(this.source, this.rows);
  final String source;
  final List<Map<String, dynamic>> rows;
  int i = 0;

  double parse() {
    final value = _expression();
    _skip();
    if (i != source.length) throw const FormatException('Trailing formula text.');
    return value;
  }

  void _skip() {
    while (i < source.length && source[i].trim().isEmpty) {
      i++;
    }
  }

  bool _take(String ch) {
    _skip();
    if (i < source.length && source[i] == ch) {
      i++;
      return true;
    }
    return false;
  }

  double _expression() {
    var result = _product();
    while (true) {
      if (_take('+')) {
        result += _product();
      } else if (_take('-')) {
        result -= _product();
      } else {
        return result;
      }
    }
  }

  double _product() {
    var result = _unary();
    while (true) {
      if (_take('*')) {
        result *= _unary();
      } else if (_take('/')) {
        final divisor = _unary();
        if (divisor == 0) throw const FormatException('Division by zero.');
        result /= divisor;
      } else {
        return result;
      }
    }
  }

  double _unary() {
    if (_take('+')) return _unary();
    if (_take('-')) return -_unary();
    return _atom();
  }

  double _atom() {
    if (_take('(')) {
      final result = _expression();
      if (!_take(')')) throw const FormatException('Missing closing parenthesis.');
      return result;
    }
    _skip();
    if (i >= source.length) throw const FormatException('Incomplete formula.');
    final number = RegExp(r'^(?:\d+(?:\.\d*)?|\.\d+)')
        .firstMatch(source.substring(i));
    if (number != null) {
      i += number.group(0)!.length;
      final value = double.parse(number.group(0)!);
      return _take('%') ? value / 100 : value;
    }
    final function = RegExp(r'^[a-zA-Z]+(?=\s*\()')
        .firstMatch(source.substring(i));
    if (function != null) {
      final name = function.group(0)!.toUpperCase();
      i += function.group(0)!.length;
      if (!_take('(')) throw const FormatException('Missing function opening bracket.');
      final values = <double>[];
      if (!_take(')')) {
        do {
          values.addAll(_argument());
        } while (_take(','));
        if (!_take(')')) throw const FormatException('Missing function closing bracket.');
      }
      if (values.isEmpty) throw const FormatException('Function needs values.');
      switch (name) {
        case 'SUM':
          return values.reduce((a, b) => a + b);
        case 'AVERAGE':
          return values.reduce((a, b) => a + b) / values.length;
        case 'MIN':
          return values.reduce((a, b) => a < b ? a : b);
        case 'MAX':
          return values.reduce((a, b) => a > b ? a : b);
        case 'COUNT':
          return values.length.toDouble();
        default:
          throw FormatException('Unsupported formula function: ' + name);
      }
    }
    final reference = _reference();
    if (reference != null) return _cell(reference);
    throw const FormatException('Unknown token in formula.');
  }

  List<double> _argument() {
    final start = i;
    final first = _reference();
    if (first != null && _take(':')) {
      final last = _reference();
      if (last == null) throw const FormatException('Invalid range.');
      return _range(first, last);
    }
    i = start;
    return [_expression()];
  }

  String? _reference() {
    _skip();
    if (i >= source.length) return null;
    final match = RegExp(r'^\$?[A-Za-z]{1,3}\$?\d+')
        .firstMatch(source.substring(i));
    if (match == null) return null;
    i += match.group(0)!.length;
    return match.group(0)!.replaceAll(r'$', '').toUpperCase();
  }

  (int, int) _indices(String reference) {
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(reference);
    if (match == null) throw const FormatException('Bad reference.');
    var col = 0;
    for (final ch in match.group(1)!.codeUnits) {
      col = col * 26 + ch - 64;
    }
    return (int.parse(match.group(2)!) - 2, col - 1);
  }

  double _cell(String reference) {
    final (row, col) = _indices(reference);
    if (row < 0 || row >= rows.length || col < 0 || col >= rows[row].length) {
      throw FormatException('Cell ' + reference + ' does not exist.');
    }
    final value = rows[row].values.elementAt(col);
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null) throw FormatException('Cell ' + reference + ' is not numeric.');
    return parsed;
  }

  List<double> _range(String first, String last) {
    final (r1, c1) = _indices(first);
    final (r2, c2) = _indices(last);
    if (r1 > r2 || c1 > c2 || (r2 - r1 + 1) * (c2 - c1 + 1) > 10000) {
      throw const FormatException('Invalid or excessive range.');
    }
    return [
      for (var row = r1; row <= r2; row++)
        for (var col = c1; col <= c2; col++)
          _cell(_label(col) + (row + 2).toString()),
    ];
  }

  String _label(int column) {
    var n = column + 1;
    var result = '';
    while (n > 0) {
      final remainder = (n - 1) % 26;
      result = String.fromCharCode(65 + remainder) + result;
      n = (n - 1) ~/ 26;
    }
    return result;
  }
}
