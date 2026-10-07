import 'dart:convert';

import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/services/sql_result_grader.dart';
import 'package:dataquest_analyst_career/services/sql_runner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
  });
  tearDown(() => database.close());

  test('SQL Lab has 20 core tasks and three-level hints', () async {
    final tasks = await _loadTasks();
    expect(tasks, hasLength(20));
    expect(tasks.where((t) => t['difficulty'] == 'Beginner'), hasLength(6));
    expect(tasks.where((t) => t['difficulty'] == 'Intermediate'), hasLength(7));
    expect(tasks.where((t) => t['difficulty'] == 'Advanced'), hasLength(7));
    for (final task in tasks) {
      expect(task['answerType'], 'sql_result');
      expect(task['hints'] as List, hasLength(3));
      expect((task['expectedAnswer'] as String).trim(), isNotEmpty);
      expect(task['expectedRows'] as List, isNotEmpty);
    }
  });

  test('all 20 reference solutions execute and grade correctly', () async {
    final tasks = await _loadTasks();
    final runner = SqlRunner(database);
    for (final task in tasks) {
      final run = await runner.runReadOnly(task['expectedAnswer'] as String);
      expect(
        run.isSuccess,
        isTrue,
        reason: '${task['id']} execution failed: ${run.error}',
      );
      final grade = SqlResultGrader.grade(
        actualRows: run.rows,
        expectedRows: (task['expectedRows'] as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList(),
      );
      expect(
        grade.isCorrect,
        isTrue,
        reason: '${task['id']} grading failed: ${grade.feedback}',
      );
    }
  });
}

Future<List<Map<String, dynamic>>> _loadTasks() async {
  final raw =
      await rootBundle.loadString('assets/content/sql_lab_core_v2.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return (decoded['tasks'] as List)
      .map((task) => Map<String, dynamic>.from(task as Map))
      .toList();
}
