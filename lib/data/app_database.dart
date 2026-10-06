import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({
    DatabaseFactory? factory,
    this.overridePath,
  }) : _factory = factory ?? databaseFactory;

  final DatabaseFactory _factory;
  final String? overridePath;
  Database? _database;

  Future<Database> get database async {
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    final path = overridePath ??
        p.join(await _factory.getDatabasesPath(), 'dataquest_v2.db');

    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await _createCoreSchema(db);
          await _seedCore(db);
          await _createPhaseThreeSchema(db);
          await _seedPhaseThree(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createPhaseThreeSchema(db);
            await _seedPhaseThree(db);
          }
        },
      ),
    );
  }

  Future<void> _createCoreSchema(Database db) async {
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
  }

  Future<void> _createPhaseThreeSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        customer_id TEXT PRIMARY KEY,
        customer_name TEXT NOT NULL,
        segment TEXT NOT NULL,
        region TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        order_id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        order_date TEXT NOT NULL,
        revenue REAL NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS boss_case_results (
        case_id TEXT PRIMARY KEY,
        completed_at TEXT NOT NULL,
        total_score INTEGER NOT NULL,
        cleaning_score INTEGER NOT NULL,
        sql_score INTEGER NOT NULL,
        kpi_score INTEGER NOT NULL,
        chart_score INTEGER NOT NULL,
        recommendation_score INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _seedCore(Database db) async {
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

  Future<void> _seedPhaseThree(Database db) async {
    final customers = <Map<String, Object?>>[
      {'customer_id': 'C001', 'customer_name': 'Asha', 'segment': 'Consumer', 'region': 'North'},
      {'customer_id': 'C002', 'customer_name': 'Ravi', 'segment': 'SMB', 'region': 'North'},
      {'customer_id': 'C003', 'customer_name': 'Meena', 'segment': 'Enterprise', 'region': 'West'},
      {'customer_id': 'C004', 'customer_name': 'Kabir', 'segment': 'Consumer', 'region': 'South'},
      {'customer_id': 'C005', 'customer_name': 'Sana', 'segment': 'Enterprise', 'region': 'East'},
    ];

    final orders = <Map<String, Object?>>[
      {'order_id': 'O2001', 'customer_id': 'C001', 'order_date': '2026-09-20', 'revenue': 1200, 'status': 'completed'},
      {'order_id': 'O2002', 'customer_id': 'C001', 'order_date': '2026-09-21', 'revenue': 800, 'status': 'completed'},
      {'order_id': 'O2003', 'customer_id': 'C002', 'order_date': '2026-09-21', 'revenue': 2300, 'status': 'completed'},
      {'order_id': 'O2004', 'customer_id': 'C003', 'order_date': '2026-09-22', 'revenue': 3200, 'status': 'completed'},
      {'order_id': 'O2005', 'customer_id': 'C003', 'order_date': '2026-09-23', 'revenue': 2000, 'status': 'completed'},
      {'order_id': 'O2006', 'customer_id': 'C004', 'order_date': '2026-09-23', 'revenue': 1400, 'status': 'refunded'},
      {'order_id': 'O2007', 'customer_id': 'C005', 'order_date': '2026-09-24', 'revenue': 2800, 'status': 'completed'},
      {'order_id': 'O2008', 'customer_id': 'C005', 'order_date': '2026-09-25', 'revenue': 900, 'status': 'cancelled'},
      {'order_id': 'O2009', 'customer_id': 'C004', 'order_date': '2026-09-26', 'revenue': 1100, 'status': 'completed'},
    ];

    final batch = db.batch();
    for (final row in customers) {
      batch.insert(
        'customers',
        row,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    for (final row in orders) {
      batch.insert(
        'orders',
        row,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
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
