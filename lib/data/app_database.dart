import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({
    DatabaseFactory? factory,
    String? overridePath,
  })  : _factory = factory ?? databaseFactory,
        _overridePath = overridePath;

  final DatabaseFactory _factory;
  final String? _overridePath;
  Database? _database;

  Future<Database> get database async {
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    final path = _overridePath ??
        p.join(await _factory.getDatabasesPath(), 'dataquest_v2.db');

    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createSchema,
      ),
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE campaign_performance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        channel TEXT NOT NULL,
        spend REAL NOT NULL,
        conversions INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customer_dirty (
        row_id INTEGER PRIMARY KEY,
        order_id TEXT,
        customer_name TEXT,
        age TEXT,
        region TEXT,
        order_date TEXT,
        amount REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE skill_mastery (
        skill_key TEXT PRIMARY KEY,
        mastery REAL NOT NULL DEFAULT 0,
        attempts INTEGER NOT NULL DEFAULT 0,
        correct_count INTEGER NOT NULL DEFAULT 0,
        next_review_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE placement_results (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        completed_at TEXT NOT NULL,
        total_score INTEGER NOT NULL
      )
    ''');

    final campaignRows = <Map<String, Object?>>[
      {'date': '2026-09-28', 'channel': 'Search', 'spend': 12000, 'conversions': 84},
      {'date': '2026-09-28', 'channel': 'Social', 'spend': 9000, 'conversions': 45},
      {'date': '2026-09-29', 'channel': 'Search', 'spend': 11500, 'conversions': 79},
      {'date': '2026-09-29', 'channel': 'Social', 'spend': 9500, 'conversions': 48},
    ];

    final dirtyRows = <Map<String, Object?>>[
      {'row_id': 1, 'order_id': 'O-1001', 'customer_name': 'Asha', 'age': '29', 'region': 'North', 'order_date': '2026-09-01', 'amount': 1250},
      {'row_id': 2, 'order_id': 'O-1002', 'customer_name': 'Ravi', 'age': '', 'region': 'north', 'order_date': '01/09/2026', 'amount': 840},
      {'row_id': 3, 'order_id': 'O-1002', 'customer_name': 'Ravi', 'age': '', 'region': 'north', 'order_date': '01/09/2026', 'amount': 840},
      {'row_id': 4, 'order_id': 'O-1003', 'customer_name': 'Meena', 'age': '34', 'region': 'NORTH', 'order_date': '2026/09/02', 'amount': 1500},
      {'row_id': 5, 'order_id': 'O-1004', 'customer_name': null, 'age': '41', 'region': 'South', 'order_date': '2026-09-03', 'amount': 2100},
      {'row_id': 6, 'order_id': 'O-1005', 'customer_name': 'Kabir', 'age': '27', 'region': 'West', 'order_date': '2026-09-04', 'amount': -999},
      {'row_id': 7, 'order_id': 'O-1006', 'customer_name': 'Sana', 'age': 'thirty', 'region': 'East', 'order_date': '2026-09-05', 'amount': 1900},
    ];

    final batch = db.batch();
    for (final row in campaignRows) {
      batch.insert('campaign_performance', row);
    }
    for (final row in dirtyRows) {
      batch.insert('customer_dirty', row);
    }
    for (final skill in const [
      'spreadsheets',
      'sql',
      'cleaning',
      'statistics',
      'business',
    ]) {
      batch.insert('skill_mastery', {'skill_key': skill});
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
