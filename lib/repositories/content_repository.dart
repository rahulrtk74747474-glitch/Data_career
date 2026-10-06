import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/analyst_task.dart';
import '../models/placement_question.dart';

class ContentRepository {
  const ContentRepository();

  Future<List<AnalystTask>> loadCareerTasks() async {
    final allTasks = <AnalystTask>[];
    for (final asset in const [
      'assets/content/phase1_tasks.json',
      'assets/content/phase2_tasks.json',
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
}
