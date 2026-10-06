import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/repositories/mastery_repository.dart';
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

  test('fresh Phase 4 database seeds Python/Pandas mastery', () async {
    final skills = await MasteryRepository(database).loadSkills();
    expect(
      skills.any((skill) => skill.skillKey == 'python'),
      isTrue,
    );
  });
}
