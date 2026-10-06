import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/analyst_task.dart';
import '../models/boss_case.dart';
import '../models/dashboard_challenge.dart';
import '../models/pandas_challenge.dart';
import '../models/placement_question.dart';

class ContentRepository {
  const ContentRepository();

  Future<List<AnalystTask>> loadCareerTasks() async {
    final allTasks = <AnalystTask>[];
    for (final asset in const [
      'assets/content/phase1_tasks.json',
      'assets/content/phase2_tasks.json',
      'assets/content/phase3_tasks.json',
      'assets/content/phase4_tasks.json',
    ]) {
      final raw = await rootBundle.loadString(asset);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final tasks = decoded['tasks'] as List<dynamic>;
      allTasks.addAll(
        tasks.map(
          (item) => AnalystTask.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      );
    }
    return allTasks;
  }

  Future<List<PlacementQuestion>> loadPlacementQuestions() async {
    final raw = await rootBundle.loadString(
      'assets/content/placement_v1.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final questions = decoded['questions'] as List<dynamic>;

    return questions
        .map(
          (item) => PlacementQuestion.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<BossCaseDefinition> loadBossCase() async {
    final raw = await rootBundle.loadString(
      'assets/content/boss_case_v1.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return BossCaseDefinition.fromJson(decoded);
  }

  Future<List<PandasChallenge>> loadPandasChallenges() async {
    final raw = await rootBundle.loadString(
      'assets/content/pandas_challenges_v1.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final challenges = decoded['challenges'] as List<dynamic>;
    return challenges
        .map(
          (item) => PandasChallenge.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<DashboardChallenge>> loadDashboardChallenges() async {
    final raw = await rootBundle.loadString(
      'assets/content/dashboard_challenges_v1.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final challenges = decoded['challenges'] as List<dynamic>;
    return challenges
        .map(
          (item) => DashboardChallenge.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
