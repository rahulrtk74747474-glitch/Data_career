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
      return SqlRunResult(
        columns: const [],
        rows: const [],
        error: 'SQLite says: $error',
      );
    }
  }
}
