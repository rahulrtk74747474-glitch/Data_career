import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/repositories/boss_case_result_repository.dart';
import 'package:dataquest_analyst_career/services/boss_case_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late BossCaseResultRepository repository;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
    repository = BossCaseResultRepository(database);
  });

  tearDown(() => database.close());

  test('boss case performance is saved and reloadable', () async {
    const score = BossCaseScore(
      cleaning: 20,
      sql: 30,
      kpi: 20,
      chart: 10,
      recommendation: 20,
    );

    await repository.save('case-1', score);
    final loaded = await repository.load('case-1');

    expect(loaded, isNotNull);
    expect(loaded!.totalScore, 100);
    expect(loaded.sqlScore, 30);
  });
}
