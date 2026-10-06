import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/repositories/evidence_repository.dart';
import 'package:dataquest_analyst_career/repositories/task_performance_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late TaskPerformanceRepository performance;
  late EvidenceRepository evidence;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
    performance = TaskPerformanceRepository(database);
    evidence = EvidenceRepository(database);
  });

  tearDown(() => database.close());

  test('repeated attempts stay immutable while best score is summarized', () async {
    await performance.record(
      id: 'bank-task',
      title: 'Bank Task',
      skillKey: 'sql',
      difficulty: 'Advanced',
      score: 70,
      mode: 'career',
      companyKey: 'bank',
    );
    await performance.record(
      id: 'bank-task',
      title: 'Bank Task',
      skillKey: 'sql',
      difficulty: 'Advanced',
      score: 92,
      mode: 'review',
      companyKey: 'bank',
    );
    await performance.record(
      id: 'bank-task',
      title: 'Bank Task',
      skillKey: 'sql',
      difficulty: 'Advanced',
      score: 80,
      mode: 'daily',
      companyKey: 'bank',
    );

    final summary = await performance.loadAll();
    final attempts = await evidence.loadAll();

    expect(summary, hasLength(1));
    expect(summary.single.bestScore, 92);
    expect(summary.single.attempts, 3);

    expect(attempts, hasLength(3));
    expect(attempts.map((item) => item.score).toSet(), {70, 92, 80});
    expect(attempts.map((item) => item.mode).toSet(), {
      'career',
      'review',
      'daily',
    });
    expect(attempts.every((item) => item.companyKey == 'bank'), isTrue);
  });
}
