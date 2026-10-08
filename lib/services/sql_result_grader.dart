class SqlResultGrade {
  const SqlResultGrade({required this.isCorrect, required this.feedback});
  final bool isCorrect;
  final String feedback;
}

class SqlResultGrader {
  const SqlResultGrader._();

  static SqlResultGrade grade({
    required List<Map<String, Object?>> actualRows,
    required List<Map<String, dynamic>> expectedRows,
    bool truncated = false,
  }) {
    if (truncated) {
      return const SqlResultGrade(
        isCorrect: false,
        feedback: 'The SQL result exceeds the 100-row preview limit. '
            'Add the requested filters or aggregation before grading.',
      );
    }
    if (actualRows.isEmpty && expectedRows.isEmpty) {
      return const SqlResultGrade(
        isCorrect: true,
        feedback: 'Correct. SQLite returned the expected empty result set.',
      );
    }
    if (actualRows.isEmpty != expectedRows.isEmpty) {
      return SqlResultGrade(
        isCorrect: false,
        feedback: actualRows.isEmpty
            ? 'The query ran, but it returned 0 rows. Check filters and joins.'
            : 'The query returned rows when the expected result is empty. Check the requested filter.',
      );
    }

    final actualColumns = _columns(actualRows.first);
    final expectedColumns = _columns(expectedRows.first);
    if (!_sameSet(actualColumns, expectedColumns)) {
      final missing = expectedColumns.difference(actualColumns).toList()..sort();
      final extra = actualColumns.difference(expectedColumns).toList()..sort();
      final details = <String>[
        if (missing.isNotEmpty) 'missing: ${missing.join(', ')}',
        if (extra.isNotEmpty) 'unexpected: ${extra.join(', ')}',
      ].join('; ');
      return SqlResultGrade(
        isCorrect: false,
        feedback:
            'The query ran, but the output columns do not match the requested result${details.isEmpty ? '.' : ' ($details).'} Check selected fields and aliases.',
      );
    }

    if (actualRows.length != expectedRows.length) {
      return SqlResultGrade(
        isCorrect: false,
        feedback:
            'The columns are correct, but SQLite returned ${actualRows.length} row(s) instead of ${expectedRows.length}. Check filters, joins, GROUP BY, HAVING and LIMIT.',
      );
    }

    final actual = _canonicalize(actualRows);
    final expected = _canonicalize(expectedRows);
    final correct = List.generate(
      actual.length,
      (index) => actual[index] == expected[index],
    ).every((match) => match);

    return SqlResultGrade(
      isCorrect: correct,
      feedback: correct
          ? 'Correct. SQLite returned the expected columns, business grain and values.'
          : 'The query ran with the right columns and row count, but one or more values do not match. Check join keys, filters, aggregation, window definitions and rounding.',
    );
  }

  static Set<String> _columns(Map<String, dynamic> row) =>
      row.keys.map((key) => key.trim().toLowerCase()).toSet();

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  static List<String> _canonicalize(List<Map<String, dynamic>> rows) {
    final canonical = rows.map((row) {
      final entries = row.entries
          .map((entry) =>
              '${entry.key.trim().toLowerCase()}=${_normalize(entry.value)}')
          .toList()
        ..sort();
      return entries.join('¦');
    }).toList()
      ..sort();
    return canonical;
  }

  static String _normalize(Object? value) {
    if (value == null) return '<null>';
    if (value is num) {
      final fixed = value.toDouble().toStringAsFixed(6);
      return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return value.toString().trim().toLowerCase();
  }
}
