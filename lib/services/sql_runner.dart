import '../data/app_database.dart';

class SqlRunResult {
  const SqlRunResult({
    required this.columns,
    required this.rows,
    required this.error,
  });

  final List<String> columns;
  final List<Map<String, Object?>> rows;
  final String? error;

  bool get isSuccess => error == null;
}

class SqlRunner {
  const SqlRunner(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<SqlRunResult> runReadOnly(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return const SqlRunResult(
        columns: [],
        rows: [],
        error: 'Write a SQL query before running it.',
      );
    }

    final normalized = query.toLowerCase();
    final startsReadOnly =
        normalized.startsWith('select ') || normalized.startsWith('with ');
    final forbidden = RegExp(
      r'\b(insert|update|delete|drop|alter|attach|detach|pragma|vacuum|replace|create)\b',
      caseSensitive: false,
    );

    final withoutTrailingSemicolon =
        query.endsWith(';') ? query.substring(0, query.length - 1) : query;

    if (!startsReadOnly ||
        forbidden.hasMatch(query) ||
        withoutTrailingSemicolon.contains(';')) {
      return const SqlRunResult(
        columns: [],
        rows: [],
        error:
            'This learning SQL runner is read-only. Use one SELECT/CTE query only.',
      );
    }

    try {
      final db = await _appDatabase.database;
      final rows = await db.rawQuery(query);
      final limitedRows = rows.take(100).toList(growable: false);
      final columns =
          limitedRows.isEmpty ? <String>[] : limitedRows.first.keys.toList();

      return SqlRunResult(
        columns: columns,
        rows: limitedRows,
        error: null,
      );
    } catch (error) {
      final raw = error.toString();
      return SqlRunResult(
        columns: const [],
        rows: const [],
        error: _plainLanguageError(raw),
      );
    }
  }

  static String _plainLanguageError(String raw) {
    final normalized = raw.toLowerCase();
    if (normalized.contains('no such table')) {
      return 'SQL error: that table name does not exist in the learning database. Check the Schema browser and copy the table name exactly.';
    }
    if (normalized.contains('no such column')) {
      return 'SQL error: one of the column names is not available in the selected table or join. Check the Schema browser and any table aliases.';
    }
    if (normalized.contains('ambiguous column name')) {
      return 'SQL error: the same column name exists in more than one joined table. Prefix it with the table name or alias, for example o.customer_id.';
    }
    if (normalized.contains('misuse of aggregate')) {
      return 'SQL error: an aggregate such as SUM, AVG or COUNT is being used at the wrong query level. Check GROUP BY, HAVING and nested-query logic.';
    }
    if (normalized.contains('misuse of window function')) {
      return 'SQL error: a window function is being used where SQLite does not allow it. Calculate the window value in SELECT (or a CTE), then filter it in an outer query.';
    }
    if (normalized.contains('no such function')) {
      return 'SQL error: SQLite does not recognize one of the functions. Check the function name and use SQLite-supported functions.';
    }
    if (normalized.contains('incomplete input')) {
      return 'SQL syntax error: the query ends before SQLite has enough information. Check unfinished parentheses, CASE/END, JOIN conditions and CTEs.';
    }
    if (normalized.contains('circular reference')) {
      return 'SQL error: a CTE refers back to itself without valid recursive CTE syntax. Check the CTE name and FROM clauses.';
    }
    if (normalized.contains('syntax error') || normalized.contains('near')) {
      return 'SQL syntax error: check commas, parentheses, aliases, quotes and clause order (SELECT → FROM/JOIN → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT).';
    }
    return 'SQLite could not run the query. Review the schema, clause order and aliases. Technical detail: $raw';
  }
}
