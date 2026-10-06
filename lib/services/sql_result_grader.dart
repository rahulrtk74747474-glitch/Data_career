class SqlResultGrade {
  const SqlResultGrade({
    required this.isCorrect,
    required this.feedback,
  });

  final bool isCorrect;
  final String feedback;
}

class SqlResultGrader {
  const SqlResultGrader._();

  static SqlResultGrade grade({
    required List<Map<String, Object?>> actualRows,
    required List<Map<String, dynamic>> expectedRows,
  }) {
    final actual = _canonicalize(actualRows);
    final expected = _canonicalize(expectedRows);

    final correct = actual.length == expected.length &&
        List.generate(actual.length, (index) => actual[index] == expected[index])
            .every((matches) => matches);

    return SqlResultGrade(
      isCorrect: correct,
      feedback: correct
          ? 'Correct. SQLite returned the expected business result.'
          : 'The query ran, but its result does not match the requested answer. Check aggregation, grouping, filters, and selected fields.',
    );
  }

  static List<String> _canonicalize(List<Map<String, dynamic>> rows) {
    final canonical = rows.map((row) {
      final values = row.values.map(_normalizeValue).toList()..sort();
      return values.join('¦');
    }).toList()
      ..sort();
    return canonical;
  }

  static String _normalizeValue(Object? value) {
    if (value == null) return '<null>';
    if (value is num) {
      final fixed = value.toDouble().toStringAsFixed(6);
      return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return value.toString().trim().toLowerCase();
  }
}
