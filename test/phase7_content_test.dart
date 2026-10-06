import 'package:dataquest_analyst_career/repositories/content_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const repository = ContentRepository();

  test('career content includes hospital operations tasks', () async {
    final tasks = await repository.loadCareerTasks();
    final hospital = tasks.where((task) => task.companyKey == 'hospital');

    expect(hospital.length, greaterThanOrEqualTo(7));
    expect(
      hospital.any((task) => task.id == 'hospital-capacity-gap-sql-001'),
      isTrue,
    );
    expect(
      hospital.any((task) => task.id == 'hospital-cohort-ops-001'),
      isTrue,
    );
  });

  test('Boss Cases include Hospital Analytics', () async {
    final cases = await repository.loadBossCases();

    expect(
      cases.any(
        (item) =>
            item.companyKey == 'hospital' &&
            item.id == 'hospital-capacity-review-001',
      ),
      isTrue,
    );
  });

  test('interview content includes chapter-gated hospital round', () async {
    final rounds = await repository.loadInterviewRounds();
    final hospital = rounds.singleWhere(
      (round) => round.key == 'hospital_analytics',
    );

    expect(hospital.companyKey, 'hospital');
    expect(hospital.minCompanyChapter, 3);
  });

  test('Daily Challenge bank includes hospital tasks', () async {
    final daily = await repository.loadDailyChallenges();

    expect(
      daily.where((item) => item.companyKey == 'hospital').length,
      greaterThanOrEqualTo(5),
    );
  });
}
