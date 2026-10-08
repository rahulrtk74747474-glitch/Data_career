import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/job_ready_v15.dart';

class JobReadyRepository {
  const JobReadyRepository();

  Future<Map<String, dynamic>> _load() async {
    final raw = await rootBundle.loadString(
      'assets/content/job_ready_v1_5.json',
    );
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<List<FlagshipWorkday>> loadWorkdays() async {
    final json = await _load();
    return (json['workdays'] as List<dynamic>)
        .map(
          (item) => FlagshipWorkday.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<List<DomainPlaybook>> loadDomainPlaybooks() async {
    final json = await _load();
    return (json['domainPlaybooks'] as List<dynamic>)
        .map(
          (item) => DomainPlaybook.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<LeadershipCase>> loadLeadershipCases() async {
    final json = await _load();
    return (json['leadershipCases'] as List<dynamic>)
        .map(
          (item) => LeadershipCase.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<AdaptiveCoachScenario>> loadCoachScenarios() async {
    final json = await _load();
    return (json['coachScenarios'] as List<dynamic>)
        .map(
          (item) => AdaptiveCoachScenario.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
