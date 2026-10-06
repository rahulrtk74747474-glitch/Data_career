class SqlColumnSchema {
  const SqlColumnSchema({
    required this.name,
    required this.type,
    required this.notNull,
    required this.primaryKey,
  });

  final String name;
  final String type;
  final bool notNull;
  final bool primaryKey;
}

class SqlTableSchema {
  const SqlTableSchema({
    required this.name,
    required this.columns,
  });

  final String name;
  final List<SqlColumnSchema> columns;
}
