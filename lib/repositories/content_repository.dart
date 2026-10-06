import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/analyst_task.dart';

class ContentRepository {
  const ContentRepository();

  Future<List<AnalystTask>> loadPhaseOneTasks() async {
    final raw = await rootBundle.loadString(
      'assets/content/phase1_tasks.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final tasks = decoded['tasks'] as List<dynamic>;

    return tasks
        .map(
          (item) => AnalystTask.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
