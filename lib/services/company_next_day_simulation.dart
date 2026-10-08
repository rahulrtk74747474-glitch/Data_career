import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Reproducible, bounded *fictional* next-day consequences. The baseline shock
/// is shared across choices, and no observational KPI changes imply causality.
class CompanyNextDayResult {
  const CompanyNextDayResult({
    required this.caseKey, required this.action, required this.cost,
    required this.service, required this.risk, required this.budget,
    required this.explanation,
  });
  final String caseKey;
  final String action;
  final int cost;
  final int service;
  final int risk;
  final int budget;
  final String explanation;

  Map<String, dynamic> toJson() => {
    'caseKey': caseKey, 'action': action,
    'cost': cost, 'service': service, 'risk': risk,
    'budget': budget, 'explanation': explanation,
  };

  factory CompanyNextDayResult.fromJson(Map<String, dynamic> json) =>
      CompanyNextDayResult(
        caseKey: json['caseKey'] as String,
        action: json['action'] as String,
        cost: (json['cost'] as num).toInt(),
        service: (json['service'] as num).toInt(),
        risk: (json['risk'] as num).toInt(),
        budget: (json['budget'] as num).toInt(),
        explanation: json['explanation'] as String,
      );
}

class CompanyNextDaySimulation {
  const CompanyNextDaySimulation._();

  static const choices = <String, String>{
    'validate': 'Validate data and pilot a small intervention',
    'scale': 'Scale the proposed intervention immediately',
    'cut': 'Cut operating expenditure now',
  };

  static CompanyNextDayResult evaluate(String caseKey, String action) {
    const keys = ['ecommerce', 'saas', 'bank', 'hospital', 'logistics'];
    final company = keys.indexOf(caseKey);
    if (company == -1 || !choices.containsKey(action)) {
      throw ArgumentError('Unknown company or intervention.');
    }
    // Company-specific starting conditions. The shared demand/capacity shock
    // should not be wrongly attributed to the learner's intervention.
    final shock = (company * 3 + 7) % 9 - 4;
    final baseBudget = 1000 - company * 40;
    final spending = switch (action) {
      'validate' => 80,
      'scale' => 260,
      _ => -120,
    };
    final serviceEffect = switch (action) {
      'validate' => 4,
      'scale' => 11,
      _ => -8,
    };
    final riskEffect = switch (action) {
      'validate' => -3,
      'scale' => 6,
      _ => 10,
    };
    final costEffect = switch (action) {
      'validate' => 5,
      'scale' => 16,
      _ => -11,
    };
    final risk = (35 + company * 3 + riskEffect + shock).clamp(0, 100);
    final service = (65 - company * 2 + serviceEffect + shock).clamp(0, 100);
    final cost = (50 + company * 2 + costEffect + shock).clamp(0, 100);
    return CompanyNextDayResult(
      caseKey: caseKey,
      action: action,
      cost: cost,
      service: service,
      risk: risk,
      budget: baseBudget - spending,
      explanation: 'The fictional company experienced a shared external '
          'demand/capacity change (' + (shock >= 0 ? '+' : '') +
          shock.toString() + ' points). '
          'The chosen policy also has modeled trade-offs. Differences are '
          'scenario assumptions—not observed causal effects. Compare a pilot '
          'or controlled experiment before recommending company-wide rollout.',
    );
  }
}

class CompanyNextDayRepository {
  const CompanyNextDayRepository();
  static const key = 'dataquest_company_next_day_v1';
  static Future<void> queue = Future<void>.value();

  Future<Map<String, CompanyNextDayResult>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return {
      for (final entry in data.entries)
        entry.key: CompanyNextDayResult.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        ),
    };
  }

  Future<CompanyNextDayResult?> load(String caseKey) async =>
      (await loadAll())[caseKey];

  Future<void> save(CompanyNextDayResult result) {
    final work = queue.then((_) async {
      final all = await loadAll();
      all[result.caseKey] = result;
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(
        key, jsonEncode({
          for (final entry in all.entries) entry.key: entry.value.toJson(),
        }),
      );
      if (!saved) throw StateError('Could not save next-day outcome.');
    });
    queue = work.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return work;
  }
}
