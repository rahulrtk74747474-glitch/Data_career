import '../data/app_database.dart';

/// Deterministic next-day operational consequences for synthetic career cases.
///
/// A training simulation, NOT observed effects or proof of causality. Every
/// decision has a data-quality/cost tradeoff and a scripted external shock.
class CompanyFollowupDay {
  const CompanyFollowupDay({
    required this.day,
    required this.company,
    required this.approach,
    required this.metricName,
    required this.metricValue,
    required this.extraCost,
    required this.risk,
    required this.managerMessage,
  });

  final int day;
  final String company;
  final String approach;
  final String metricName;
  final double metricValue;
  final double extraCost;
  final double risk;
  final String managerMessage;

  factory CompanyFollowupDay.fromRow(Map<String, Object?> data) =>
      CompanyFollowupDay(
        day: (data['day_number'] as num).toInt(),
        company: data['company'] as String,
        approach: data['approach'] as String,
        metricName: data['metric_name'] as String,
        metricValue: (data['metric_value'] as num).toDouble(),
        extraCost: (data['extra_cost'] as num).toDouble(),
        risk: (data['risk_score'] as num).toDouble(),
        managerMessage: data['manager_message'] as String,
      );
}

class CompanyFollowupService {
  const CompanyFollowupService(this.database);
  final AppDatabase database;

  static const table = 'dq_company_followup_daily';
  static const _baselines = <String, (String, double, bool)>{
    'ecommerce': ('Refund complaint rate (%)', 9.0, false),
    'saas': ('Active MRR (INR)', 13800.0, true),
    'bank': ('High-risk exposure (INR)', 500000.0, false),
    'hospital': ('Emergency wait minutes', 59.0, false),
    'logistics': ('On-time delivery rate (%)', 84.0, true),
  };

  static String chooseApproach(String text) {
    final normalized = text.toLowerCase();
    if (RegExp(r'\b(pilot|experiment|test|trial|a/b)\b').hasMatch(normalized)) {
      return 'controlled_pilot';
    }
    if (RegExp(r'\b(rollout|roll-out|expand|launch|implement)\b').hasMatch(normalized)) {
      return 'broad_rollout';
    }
    return 'investigate_first';
  }

  Future<void> _ensureTable() async {
    final db = await database.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $table (
        workday_id TEXT NOT NULL,
        day_number INTEGER NOT NULL,
        company TEXT NOT NULL,
        approach TEXT NOT NULL,
        metric_name TEXT NOT NULL,
        metric_value REAL NOT NULL,
        extra_cost REAL NOT NULL,
        risk_score REAL NOT NULL,
        manager_message TEXT NOT NULL,
        PRIMARY KEY (workday_id, day_number)
      )
    ''');
  }

  Future<List<CompanyFollowupDay>> record({
    required String workdayId,
    required String company,
    required int score,
    required int hintsUsed,
    required String managerRecommendation,
  }) async {
    final baseline = _baselines[company];
    if (baseline == null) throw ArgumentError.value(company, 'company');
    await _ensureTable();
    final db = await database.database;
    final prior = await load(workdayId);
    if (prior.isNotEmpty) return prior;
    final approach = chooseApproach(managerRecommendation);
    final magnitude = (score.clamp(0, 100) / 100.0) *
        (hintsUsed == 0 ? 1.0 : 0.75);
    // Intervention benefits are assumed, not estimated from real data.
    final policyFactor = switch (approach) {
      'controlled_pilot' => 0.75,
      'broad_rollout' => 1.25,
      _ => 0.25,
    };
    final direction = baseline.$3 ? 1.0 : -1.0;
    final change = baseline.$2 * 0.07 * magnitude * policyFactor;
    final spending = switch (approach) {
      'controlled_pilot' => 500.0,
      'broad_rollout' => 1600.0,
      _ => 125.0,
    };
    final incident = switch (company) {
      'ecommerce' => 'A marketing campaign changes the order mix.',
      'saas' => 'Two renewals move to the following billing cycle.',
      'bank' => 'A sector-level credit alert raises review workload.',
      'hospital' => 'Unplanned staff absence increases arrival pressure.',
      _ => 'A major route experiences an external weather delay.',
    };
    final values = <double>[
      baseline.$2,
      baseline.$2 + direction * change * 0.6,
      baseline.$2 + direction * change * 0.35,
      baseline.$2 + direction * change,
    ];
    // Never allow impossible negative money/time/percentages.
    double safeValue(double value) =>
        baseline.$1.contains('(%)') ? value.clamp(0.0, 100.0).toDouble()
            : value < 0 ? 0.0 : value;
    await db.transaction((txn) async {
      for (var day = 0; day <= 3; day++) {
        final statement = switch (day) {
          0 => 'Baseline before your recommendation. Review definitions first.',
          1 => 'The simulated intervention starts. Additional operating cost is incurred.',
          2 => '$incident Compare the change with the baseline; do not assume causality.',
          _ => 'Manager review: reconcile outcomes, cost and alternative causes before scaling.',
        };
        await txn.insert(table, <String, Object?>{
          'workday_id': workdayId,
          'day_number': day,
          'company': company,
          'approach': approach,
          'metric_name': baseline.$1,
          'metric_value': safeValue(values[day]),
          'extra_cost': day == 0 ? 0.0 : spending * day,
          'risk_score': (50 + (approach == 'broad_rollout' ? 10 : 0) -
                  magnitude * day * 4 + (day == 2 ? 8 : 0))
              .clamp(0.0, 100.0).toDouble(),
          'manager_message': statement,
        });
      }
    });
    return load(workdayId);
  }

  Future<List<CompanyFollowupDay>> load(String workdayId) async {
    await _ensureTable();
    final db = await database.database;
    final data = await db.query(
      table,
      where: 'workday_id = ?',
      whereArgs: [workdayId],
      orderBy: 'day_number',
    );
    return data.map(CompanyFollowupDay.fromRow).toList();
  }
}
