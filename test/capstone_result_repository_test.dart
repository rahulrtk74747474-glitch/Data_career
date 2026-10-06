import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/repositories/capstone_result_repository.dart';
import 'package:dataquest_analyst_career/repositories/evidence_repository.dart';
import 'package:dataquest_analyst_career/services/capstone_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
  });

  tearDown(() => database.close());

  test('saving capstone writes latest result and immutable attempt', () async {
    final repository = CapstoneResultRepository(database);
    const score = CapstoneScore(
      cleaning: 15,
      sql: 25,
      statistics: 15,
      kpi: 15,
      dashboard: 10,
      recommendation: 20,
    );

    await repository.save(
      capstoneId: 'final',
      title: 'Final Capstone',
      score: score,
    );

    final saved = await repository.load('final');
    final evidence = await EvidenceRepository(database).loadAll();

    expect(saved, isNotNull);
    expect(saved!.totalScore, 100);
    expect(evidence, hasLength(1));
    expect(evidence.single.sourceType, 'capstone');
    expect(evidence.single.companyKey, 'cross_company');
  });
}
