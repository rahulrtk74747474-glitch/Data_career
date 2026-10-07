import 'package:dataquest_analyst_career/models/content_pack.dart';
import 'package:dataquest_analyst_career/services/task_pack_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generator creates 25 schema-v2 tasks for arbitrary skill and level', () {
    final json = TaskPackGenerator.generate(
      skill: 'Forecasting & ML',
      level: 'Advanced',
    );

    final pack = ContentPack.fromJson(json);
    expect(pack.schemaVersion, 2);
    expect(pack.tasks, hasLength(25));
    expect(pack.datasets, hasLength(5));
    expect(
      pack.tasks.map((task) => task['skillKey']).toSet(),
      {'forecasting-ml'},
    );
    expect(
      pack.tasks.map((task) => task['difficulty']).toSet(),
      {'Advanced'},
    );
    expect(
      pack.tasks.map((task) => task['companyKey']).toSet(),
      {'ecommerce', 'saas', 'bank', 'hospital', 'logistics'},
    );
    for (final task in pack.tasks) {
      expect(task['hints'] as List<dynamic>, hasLength(3));
      expect(task['expectedAnswer'].toString(), isNotEmpty);
    }
  });

  test('generator validates input bounds', () {
    expect(
      () => TaskPackGenerator.generate(
        skill: '',
        level: 'Beginner',
      ),
      throwsFormatException,
    );
    expect(
      () => TaskPackGenerator.generate(
        skill: 'SQL',
        level: 'Beginner',
        count: 101,
      ),
      throwsRangeError,
    );
  });
}
