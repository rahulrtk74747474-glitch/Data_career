import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/repositories/evidence_repository.dart';
import 'package:dataquest_analyst_career/repositories/interview_result_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late InterviewResultRepository repository;
  late EvidenceRepository evidence;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
    repository = InterviewResultRepository(database);
    evidence = EvidenceRepository(database);
  });

  tearDown(() => database.close());

  test('repository keeps best/latest summary and every interview attempt', () async {
    await repository.save(
      roundKey: 'bank_analytics',
      score: 82,
      timed: false,
      companyKey: 'bank',
    );
    await repository.save(
      roundKey: 'bank_analytics',
      score: 71,
      timed: true,
      companyKey: 'bank',
    );

    final results = await repository.loadAll();
    expect(results, hasLength(1));
    expect(results.single.bestScore, 82);
    expect(results.single.latestScore, 71);
    expect(results.single.attempts, 2);
    expect(results.single.lastMode, 'timed');

    final history = await evidence.loadAll();
    expect(history, hasLength(2));
    expect(history.first.sourceType, 'interview');
    expect(history.first.companyKey, 'bank');
    expect(history.map((item) => item.score).toSet(), {82, 71});
  });
}
