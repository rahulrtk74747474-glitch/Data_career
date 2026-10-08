import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const forbidden = [
    'correlation proves causation',
    'p-value is the probability the null is true',
    'p value is the probability the null is true',
    'p > 0.05 proves',
    'p>0.05 proves',
    'every outlier is an error',
    'nrr above 100% means no churn',
  ];

  test('trusted educational fields avoid known-invalid claims', () async {
    final trusted = <String>[];

    final foundation =
        await _asset('assets/content/foundation_academy_v1.json');
    for (final raw in foundation['lessons'] as List<dynamic>) {
      final item = Map<String, dynamic>.from(raw as Map);
      trusted.addAll([
        item['explanation'] as String,
        item['solution'] as String,
        item['correctAnswer'] as String,
      ]);
    }

    final dashboards =
        await _asset('assets/content/dashboard_challenges_v1.json');
    for (final raw in dashboards['challenges'] as List<dynamic>) {
      final item = Map<String, dynamic>.from(raw as Map);
      trusted.addAll([
        item['explanation'] as String,
        item['correctOption'] as String,
      ]);
    }

    final narrative = await _asset('assets/content/narrative_v1.json');
    for (final raw in narrative['insightScenarios'] as List<dynamic>) {
      final item = Map<String, dynamic>.from(raw as Map);
      final model = (item['modelAnswer'] as String?) ?? '';
      if (model.isNotEmpty) trusted.add(model);
    }

    final v15 = await _asset('assets/content/job_ready_v1_5.json');
    for (final raw in v15['workdays'] as List<dynamic>) {
      final item = Map<String, dynamic>.from(raw as Map);
      trusted.addAll([
        item['statisticsExpected'] as String,
        item['managerReference'] as String,
        item['reviewFeedback'] as String,
      ]);
    }

    final normalized = trusted.join('\n').toLowerCase();
    for (final phrase in forbidden) {
      expect(
        normalized.contains(phrase),
        isFalse,
        reason: 'Trusted content contains invalid claim: $phrase',
      );
    }
  });

  test('flagship manager references include uncertainty and next action', () async {
    final v15 = await _asset('assets/content/job_ready_v1_5.json');
    for (final raw in v15['workdays'] as List<dynamic>) {
      final item = Map<String, dynamic>.from(raw as Map);
      final reference = (item['managerReference'] as String).toLowerCase();
      final uncertainty = List<String>.from(
        item['uncertaintyTerms'] as List<dynamic>,
      );
      final recommendations = List<String>.from(
        item['recommendationTerms'] as List<dynamic>,
      );

      expect(
        uncertainty.any((term) => reference.contains(term.toLowerCase())),
        isTrue,
        reason: '${item['id']} lacks uncertainty language',
      );
      expect(
        recommendations.any((term) => reference.contains(term.toLowerCase())),
        isTrue,
        reason: '${item['id']} lacks recommendation language',
      );
    }
  });
}

Future<Map<String, dynamic>> _asset(String path) async {
  final raw = await rootBundle.loadString(path);
  return jsonDecode(raw) as Map<String, dynamic>;
}
