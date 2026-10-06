import '../data/app_database.dart';
import '../models/sql_table_schema.dart';

class SqlWorkspaceRepository {
  const SqlWorkspaceRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  static const _learningTables = {
    'campaign_performance',
    'customer_dirty',
    'customers',
    'orders',
  };

  Future<List<SqlTableSchema>> loadSchemas() async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    );

    final schemas = <SqlTableSchema>[];
    for (final row in rows) {
      final table = row['name'] as String;
      if (!_learningTables.contains(table)) continue;

      final columns = await db.rawQuery(
        'PRAGMA table_info(' + _quoteIdentifier(table) + ')',
      );

      schemas.add(
        SqlTableSchema(
          name: table,
          columns: [
            for (final column in columns)
              SqlColumnSchema(
                name: column['name'] as String,
                type: (column['type'] as String?) ?? '',
                notNull: (column['notnull'] as num).toInt() == 1,
                primaryKey: (column['pk'] as num).toInt() == 1,
              ),
          ],
        ),
      );
    }
    return schemas;
  }

  Future<List<Map<String, Object?>>> previewTable(
    String table, {
    int limit = 8,
  }) async {
    if (!_learningTables.contains(table)) {
      throw ArgumentError.value(table, 'table', 'Unknown learning table');
    }

    final safeLimit = limit.clamp(1, 20).toInt();
    final db = await _appDatabase.database;
    return db.rawQuery(
      'SELECT * FROM ' + _quoteIdentifier(table) + ' LIMIT ?',
      [safeLimit],
    );
  }

  static String _quoteIdentifier(String identifier) {
    return '"' + identifier.replaceAll('"', '""') + '"';
  }
}
