import 'package:dataquest_analyst_career/features/game/game_progress.dart';
import 'package:dataquest_analyst_career/models/analyst_task.dart';
import 'package:dataquest_analyst_career/services/career_task_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tasks = [
    _task('e-beginner', 'Beginner', 'ecommerce', 0),
    _task('e-intermediate', 'Intermediate', 'ecommerce', 1),
    _task('s-intermediate', 'Intermediate', 'saas', 2),
    _task('s-advanced', 'Advanced', 'saas', 3),
    _task('b-advanced', 'Advanced', 'bank', 4),
    _task('h-advanced', 'Advanced', 'hospital', 5),
    _task('l-advanced', 'Advanced', 'logistics', 5),
  ];

  test('intern sees only beginner ecommerce tickets', () {
    final visible = CareerTaskService.visibleTasks(
      progress: _progress(level: 0),
      tasks: tasks,
    );
    expect(visible.map((task) => task.id).toList(), ['e-beginner']);
  });

  test('Data Analyst sees SaaS intermediate tickets', () {
    final visible = CareerTaskService.visibleTasks(
      progress: _progress(level: 2),
      tasks: tasks,
    );
    expect(visible.map((task) => task.id).toList(), ['s-intermediate']);
  });

  test('Senior can see intermediate and advanced SaaS tickets', () {
    final visible = CareerTaskService.visibleTasks(
      progress: _progress(level: 3),
      tasks: tasks,
    );
    expect(
      visible.map((task) => task.id).toSet(),
      {'s-intermediate', 's-advanced'},
    );
  });

  test('Lead Analyst sees banking tickets', () {
    final visible = CareerTaskService.visibleTasks(
      progress: _progress(level: 4),
      tasks: tasks,
    );

    expect(visible.map((task) => task.id).toList(), ['b-advanced']);
  });

  test('Head of Analytics can work hospital chapter independently', () {
    final visible = CareerTaskService.visibleTasks(
      progress: _progress(level: 5, companyChapter: 3),
      tasks: tasks,
    );

    expect(visible.map((task) => task.id).toList(), ['h-advanced']);
  });

  test('Head of Analytics can work logistics chapter independently', () {
    final visible = CareerTaskService.visibleTasks(
      progress: _progress(level: 5, companyChapter: 4),
      tasks: tasks,
    );

    expect(visible.map((task) => task.id).toList(), ['l-advanced']);
  });
}

GameProgress _progress({
  required int level,
  int companyChapter = -1,
}) {
  return GameProgress(
    xp: 1000,
    streak: 0,
    completedTaskIds: const {},
    revenueIndex: 100,
    churnRate: 8,
    costIndex: 100,
    satisfaction: 70,
    careerLevel: level,
    dailyStreak: 0,
    lastDailyDate: null,
    completedDailyDates: const {},
    companyChapter: companyChapter,
  );
}

AnalystTask _task(
  String id,
  String difficulty,
  String company,
  int minLevel,
) {
  return AnalystTask(
    id: id,
    title: id,
    department: 'CEO',
    skill: 'Business Analytics',
    skillKey: 'business',
    context: '',
    goal: '',
    deliverable: '',
    answerType: 'choice',
    prompt: '',
    expectedAnswer: 'A',
    requiredTokens: const [],
    expectedRows: const [],
    expectedSelections: const [],
    hints: const ['1', '2', '3'],
    explanation: '',
    xp: 50,
    datasetName: '',
    rows: const [],
    options: const ['A', 'B'],
    difficulty: difficulty,
    companyKey: company,
    minCareerLevel: minLevel,
  );
}
