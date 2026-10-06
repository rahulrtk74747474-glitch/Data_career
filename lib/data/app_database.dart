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
        version: 6,
        onCreate: (db, version) async {
          await _createCoreSchema(db);
          await _seedCore(db);
          await _createPhaseThreeSchema(db);
          await _seedPhaseThree(db);
          await _createPhaseFourSchema(db);
          await _seedPhaseFour(db);
          await _createPhaseFiveSchema(db);
          await _createPhaseSixSchema(db);
          await _seedPhaseSix(db);
          await _createPhaseSevenSchema(db);
          await _seedPhaseSeven(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createPhaseThreeSchema(db);
            await _seedPhaseThree(db);
          }
          if (oldVersion < 3) {
            await _createPhaseFourSchema(db);
            await _seedPhaseFour(db);
          }
          if (oldVersion < 4) {
            await _createPhaseFiveSchema(db);
          }
          if (oldVersion < 5) {
            await _createPhaseSixSchema(db);
            await _seedPhaseSix(db);
          }
          if (oldVersion < 6) {
            await _createPhaseSevenSchema(db);
            await _seedPhaseSeven(db);
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

  Future<void> _createPhaseFourSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_performance (
        task_id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        skill_key TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        best_score INTEGER NOT NULL,
        attempts INTEGER NOT NULL,
        last_completed_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPhaseFiveSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS interview_results (
        round_key TEXT PRIMARY KEY,
        completed_at TEXT NOT NULL,
        best_score INTEGER NOT NULL,
        latest_score INTEGER NOT NULL,
        attempts INTEGER NOT NULL,
        last_mode TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPhaseSixSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bank_accounts (
        account_id TEXT PRIMARY KEY,
        segment TEXT NOT NULL,
        region TEXT NOT NULL,
        tenure_months INTEGER NOT NULL,
        avg_balance REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS loan_portfolio (
        loan_id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        product TEXT NOT NULL,
        outstanding REAL NOT NULL,
        dpd INTEGER NOT NULL,
        risk_band TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bank_transactions (
        txn_id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        txn_date TEXT NOT NULL,
        amount REAL NOT NULL,
        channel TEXT NOT NULL,
        review_flag INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS evidence_attempts (
        attempt_id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_type TEXT NOT NULL,
        source_id TEXT NOT NULL,
        title TEXT NOT NULL,
        skill_key TEXT NOT NULL,
        score INTEGER NOT NULL,
        mode TEXT NOT NULL,
        company_key TEXT NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createPhaseSevenSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hospital_daily_ops (
        ops_date TEXT NOT NULL,
        unit TEXT NOT NULL,
        arrivals INTEGER NOT NULL,
        completed_visits INTEGER NOT NULL,
        staffed_beds INTEGER NOT NULL,
        occupied_beds INTEGER NOT NULL,
        avg_wait_minutes REAL NOT NULL,
        cancellations INTEGER NOT NULL,
        PRIMARY KEY (ops_date, unit)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS hospital_capacity_forecast (
        day_name TEXT PRIMARY KEY,
        expected_arrivals INTEGER NOT NULL,
        planned_capacity INTEGER NOT NULL
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

  Future<void> _seedPhaseFour(Database db) async {
    await db.insert(
      'skill_mastery',
      {'skill_key': 'python'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _seedPhaseSix(Database db) async {
    final accounts = <Map<String, Object?>>[
      {'account_id': 'A001', 'segment': 'Retail', 'region': 'North', 'tenure_months': 24, 'avg_balance': 85000},
      {'account_id': 'A002', 'segment': 'Retail', 'region': 'West', 'tenure_months': 8, 'avg_balance': 35000},
      {'account_id': 'A003', 'segment': 'SME', 'region': 'North', 'tenure_months': 36, 'avg_balance': 240000},
      {'account_id': 'A004', 'segment': 'SME', 'region': 'South', 'tenure_months': 18, 'avg_balance': 180000},
      {'account_id': 'A005', 'segment': 'Affluent', 'region': 'East', 'tenure_months': 48, 'avg_balance': 600000},
      {'account_id': 'A006', 'segment': 'Retail', 'region': 'South', 'tenure_months': 5, 'avg_balance': 22000},
    ];

    final loans = <Map<String, Object?>>[
      {'loan_id': 'L001', 'account_id': 'A001', 'product': 'Personal', 'outstanding': 120000, 'dpd': 0, 'risk_band': 'Low'},
      {'loan_id': 'L002', 'account_id': 'A002', 'product': 'CreditCard', 'outstanding': 45000, 'dpd': 18, 'risk_band': 'Medium'},
      {'loan_id': 'L003', 'account_id': 'A003', 'product': 'Business', 'outstanding': 500000, 'dpd': 0, 'risk_band': 'Low'},
      {'loan_id': 'L004', 'account_id': 'A004', 'product': 'Business', 'outstanding': 420000, 'dpd': 42, 'risk_band': 'High'},
      {'loan_id': 'L005', 'account_id': 'A005', 'product': 'Home', 'outstanding': 1800000, 'dpd': 0, 'risk_band': 'Low'},
      {'loan_id': 'L006', 'account_id': 'A006', 'product': 'Personal', 'outstanding': 80000, 'dpd': 65, 'risk_band': 'High'},
    ];

    final transactions = <Map<String, Object?>>[
      {'txn_id': 'T001', 'account_id': 'A001', 'txn_date': '2026-10-01', 'amount': 6500, 'channel': 'card', 'review_flag': 0},
      {'txn_id': 'T002', 'account_id': 'A002', 'txn_date': '2026-10-01', 'amount': 48000, 'channel': 'online', 'review_flag': 1},
      {'txn_id': 'T003', 'account_id': 'A003', 'txn_date': '2026-10-02', 'amount': 125000, 'channel': 'rtgs', 'review_flag': 0},
      {'txn_id': 'T004', 'account_id': 'A004', 'txn_date': '2026-10-02', 'amount': 210000, 'channel': 'online', 'review_flag': 1},
      {'txn_id': 'T005', 'account_id': 'A005', 'txn_date': '2026-10-03', 'amount': 76000, 'channel': 'card', 'review_flag': 0},
      {'txn_id': 'T006', 'account_id': 'A006', 'txn_date': '2026-10-03', 'amount': 32000, 'channel': 'atm', 'review_flag': 1},
      {'txn_id': 'T007', 'account_id': 'A002', 'txn_date': '2026-10-04', 'amount': 1200, 'channel': 'card', 'review_flag': 0},
    ];

    final batch = db.batch();
    for (final row in accounts) {
      batch.insert(
        'bank_accounts',
        row,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    for (final row in loans) {
      batch.insert(
        'loan_portfolio',
        row,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    for (final row in transactions) {
      batch.insert(
        'bank_transactions',
        row,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedPhaseSeven(Database db) async {
    final operations = <Map<String, Object?>>[
      {'ops_date': '2026-10-01', 'unit': 'Emergency', 'arrivals': 120, 'completed_visits': 108, 'staffed_beds': 40, 'occupied_beds': 38, 'avg_wait_minutes': 52, 'cancellations': 0},
      {'ops_date': '2026-10-01', 'unit': 'Outpatient', 'arrivals': 180, 'completed_visits': 165, 'staffed_beds': 0, 'occupied_beds': 0, 'avg_wait_minutes': 31, 'cancellations': 15},
      {'ops_date': '2026-10-02', 'unit': 'Emergency', 'arrivals': 135, 'completed_visits': 120, 'staffed_beds': 40, 'occupied_beds': 40, 'avg_wait_minutes': 68, 'cancellations': 0},
      {'ops_date': '2026-10-02', 'unit': 'Outpatient', 'arrivals': 170, 'completed_visits': 160, 'staffed_beds': 0, 'occupied_beds': 0, 'avg_wait_minutes': 28, 'cancellations': 10},
      {'ops_date': '2026-10-03', 'unit': 'Emergency', 'arrivals': 110, 'completed_visits': 104, 'staffed_beds': 40, 'occupied_beds': 36, 'avg_wait_minutes': 44, 'cancellations': 0},
      {'ops_date': '2026-10-03', 'unit': 'Outpatient', 'arrivals': 190, 'completed_visits': 172, 'staffed_beds': 0, 'occupied_beds': 0, 'avg_wait_minutes': 35, 'cancellations': 18},
      {'ops_date': '2026-10-04', 'unit': 'Emergency', 'arrivals': 145, 'completed_visits': 128, 'staffed_beds': 40, 'occupied_beds': 39, 'avg_wait_minutes': 72, 'cancellations': 0},
      {'ops_date': '2026-10-04', 'unit': 'Outpatient', 'arrivals': 160, 'completed_visits': 152, 'staffed_beds': 0, 'occupied_beds': 0, 'avg_wait_minutes': 26, 'cancellations': 8},
    ];

    final forecast = <Map<String, Object?>>[
      {'day_name': 'Monday', 'expected_arrivals': 130, 'planned_capacity': 140},
      {'day_name': 'Tuesday', 'expected_arrivals': 135, 'planned_capacity': 140},
      {'day_name': 'Wednesday', 'expected_arrivals': 140, 'planned_capacity': 140},
      {'day_name': 'Thursday', 'expected_arrivals': 150, 'planned_capacity': 145},
      {'day_name': 'Friday', 'expected_arrivals': 165, 'planned_capacity': 150},
      {'day_name': 'Saturday', 'expected_arrivals': 180, 'planned_capacity': 155},
      {'day_name': 'Sunday', 'expected_arrivals': 155, 'planned_capacity': 150},
    ];

    final batch = db.batch();
    for (final row in operations) {
      batch.insert(
        'hospital_daily_ops',
        row,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    for (final row in forecast) {
      batch.insert(
        'hospital_capacity_forecast',
        row,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<String> get storageDirectoryPath async {
    final databasePath = overridePath ??
        p.join(await _factory.getDatabasesPath(), 'dataquest_v2.db');
    return p.dirname(databasePath);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
