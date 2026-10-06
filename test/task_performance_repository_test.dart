import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/repositories/task_performance_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late TaskPerformanceRepository repository;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
    repository = TaskPerformanceRepository(database);
  });

  tearDown(() => database.close());

  test('performance keeps strongest score while counting attempts', () async {
    await repository.record(
      id: 'task-1',
      title: 'Task One',
      skillKey: 'sql',
      difficulty: 'Intermediate',
      score: 70,
    );
    await repository.record(
      id: 'task-1',
      title: 'Task One',
      skillKey: 'sql',
      difficulty: 'Intermediate',
      score: 92,
    );
    await repository.record(
      id: 'task-1',
      title: 'Task One',
      skillKey: 'sql',
      difficulty: 'Intermediate',
      score: 80,
    );

    final items = await repository.loadAll();
    expect(items, hasLength(1));
    expect(items.single.bestScore, 92);
    expect(items.single.attempts, 3);
  });
}
