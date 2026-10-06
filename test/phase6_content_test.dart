import 'package:dataquest_analyst_career/repositories/content_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const repository = ContentRepository();

  test('career content includes bank analytics tasks', () async {
    final tasks = await repository.loadCareerTasks();

    expect(
      tasks.any(
        (task) =>
            task.companyKey == 'bank' &&
            task.id == 'bank-credit-risk-sql-001',
      ),
      isTrue,
    );
    expect(
      tasks.where((task) => task.companyKey == 'bank').length,
      greaterThanOrEqualTo(4),
    );
  });

  test('Boss Case content covers ecommerce, SaaS and bank', () async {
    final cases = await repository.loadBossCases();

    expect(cases.map((item) => item.companyKey).toSet(), {
      'ecommerce',
      'saas',
      'bank',
      'hospital',
    });
  });

  test('interview content includes advanced banking round', () async {
    final rounds = await repository.loadInterviewRounds();

    expect(
      rounds.any((round) => round.key == 'bank_analytics'),
      isTrue,
    );
  });
}
