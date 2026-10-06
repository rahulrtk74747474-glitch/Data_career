import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/repositories/interview_result_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late InterviewResultRepository repository;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
    repository = InterviewResultRepository(database);
  });

  tearDown(() => database.close());

  test('repository keeps best score and latest attempt', () async {
    await repository.save(
      roundKey: 'sql',
      score: 82,
      timed: false,
    );
    await repository.save(
      roundKey: 'sql',
      score: 71,
      timed: true,
    );

    final results = await repository.loadAll();
    expect(results, hasLength(1));
    expect(results.single.bestScore, 82);
    expect(results.single.latestScore, 71);
    expect(results.single.attempts, 2);
    expect(results.single.lastMode, 'timed');
  });
}
