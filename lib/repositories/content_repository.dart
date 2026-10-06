import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/analyst_task.dart';
import '../models/analytics_challenge.dart';
import '../models/boss_case.dart';
import '../models/capstone.dart';
import '../models/dashboard_challenge.dart';
import '../models/daily_challenge.dart';
import '../models/interview.dart';
import '../models/pandas_challenge.dart';
import '../models/placement_question.dart';
import '../models/spreadsheet_challenge.dart';

class ContentRepository {
  const ContentRepository();

  Future<List<AnalystTask>> loadCareerTasks() async {
    final allTasks = <AnalystTask>[];
    for (final asset in const [
      'assets/content/phase1_tasks.json',
      'assets/content/phase2_tasks.json',
      'assets/content/phase3_tasks.json',
      'assets/content/phase4_tasks.json',
      'assets/content/saas_retention_v1.json',
      'assets/content/saas_sql_v1.json',
      'assets/content/saas_statistics_v1.json',
      'assets/content/saas_nrr_v1.json',
      'assets/content/bank_tasks_v1.json',
      'assets/content/hospital_tasks_v1.json',
      'assets/content/logistics_tasks_v1.json',
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
    final cases = await loadBossCases();
    return cases.first;
  }

  Future<List<BossCaseDefinition>> loadBossCases() async {
    final cases = <BossCaseDefinition>[];
    for (final asset in const [
      'assets/content/boss_case_v1.json',
      'assets/content/boss_case_saas_v1.json',
      'assets/content/boss_case_bank_v1.json',
      'assets/content/boss_case_hospital_v1.json',
      'assets/content/boss_case_logistics_v1.json',
    ]) {
      final raw = await rootBundle.loadString(asset);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      cases.add(BossCaseDefinition.fromJson(decoded));
    }
    return cases;
  }

  Future<CapstoneDefinition> loadCapstone() async {
    final raw = await rootBundle.loadString(
      'assets/content/capstone_v1.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return CapstoneDefinition.fromJson(decoded);
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

  Future<List<SpreadsheetChallenge>> loadSpreadsheetChallenges() async {
    final raw = await rootBundle.loadString(
      'assets/content/spreadsheet_cleaning_v1.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final challenges = decoded['challenges'] as List<dynamic>;
    return challenges
        .map(
          (item) => SpreadsheetChallenge.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<AnalyticsChallenge>> loadAnalyticsChallenges() async {
    final raw = await rootBundle.loadString(
      'assets/content/analytics_studio_v1.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final challenges = decoded['challenges'] as List<dynamic>;
    return challenges
        .map(
          (item) => AnalyticsChallenge.fromJson(
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

  Future<List<DailyChallengeDefinition>> loadDailyChallenges() async {
    final raw = await rootBundle.loadString(
      'assets/content/daily_challenges_v1.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final challenges = decoded['challenges'] as List<dynamic>;
    return challenges
        .map(
          (item) => DailyChallengeDefinition.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<InterviewRoundDefinition>> loadInterviewRounds() async {
    final allRounds = <InterviewRoundDefinition>[];
    for (final asset in const [
      'assets/content/interview_sql_v1.json',
      'assets/content/interview_statistics_v1.json',
      'assets/content/interview_case_v1.json',
      'assets/content/interview_behavioral_v1.json',
      'assets/content/interview_bank_v1.json',
      'assets/content/interview_hospital_v1.json',
      'assets/content/interview_logistics_v1.json',
      'assets/content/interview_gauntlet_v1.json',
    ]) {
      final raw = await rootBundle.loadString(asset);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final rounds = decoded['rounds'] as List<dynamic>;
      allRounds.addAll(
        rounds.map(
          (item) => InterviewRoundDefinition.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      );
    }
    return allRounds;
  }
}
