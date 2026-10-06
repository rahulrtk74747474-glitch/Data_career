import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/repositories/mastery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase appDatabase;
  late MasteryRepository repository;

  setUp(() {
    sqfliteFfiInit();
    appDatabase = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
    repository = MasteryRepository(appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('placement scores persist into the skill model', () async {
    await repository.applyPlacement({
      'spreadsheets': 80,
      'sql': 30,
      'cleaning': 80,
      'statistics': 30,
      'business': 80,
    });

    expect(await repository.hasCompletedPlacement(), isTrue);
    final skills = await repository.loadSkills();
    final sql = skills.firstWhere((skill) => skill.skillKey == 'sql');

    expect(sql.mastery, 30);
    expect(sql.isWeak, isTrue);
    expect(sql.nextReviewAt, isNotNull);
  });

  test('task attempt updates mastery and review date', () async {
    await repository.recordAttempt('sql', 90);
    final skills = await repository.loadSkills();
    final sql = skills.firstWhere((skill) => skill.skillKey == 'sql');

    expect(sql.mastery, 90);
    expect(sql.attempts, 1);
    expect(sql.correct, 1);
    expect(sql.nextReviewAt, isNotNull);
  });
}
