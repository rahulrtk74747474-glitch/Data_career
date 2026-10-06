import 'package:dataquest_analyst_career/repositories/content_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const repository = ContentRepository();

  test('career content includes logistics network tasks', () async {
    final tasks = await repository.loadCareerTasks();
    final logistics = tasks.where((task) => task.companyKey == 'logistics');

    expect(logistics.length, greaterThanOrEqualTo(8));
    expect(
      logistics.any((task) => task.id == 'logistics-sla-sql-001'),
      isTrue,
    );
    expect(
      logistics.any(
        (task) => task.id == 'logistics-warehouse-utilization-sql-001',
      ),
      isTrue,
    );
    expect(
      logistics.any((task) => task.id == 'logistics-cost-sql-001'),
      isTrue,
    );
  });

  test('Boss Cases include Logistics Analytics', () async {
    final cases = await repository.loadBossCases();

    expect(
      cases.any(
        (item) =>
            item.companyKey == 'logistics' &&
            item.id == 'logistics-network-review-001',
      ),
      isTrue,
    );
  });

  test('interview content includes chapter-gated logistics round', () async {
    final rounds = await repository.loadInterviewRounds();
    final logistics = rounds.singleWhere(
      (round) => round.key == 'logistics_analytics',
    );

    expect(logistics.companyKey, 'logistics');
    expect(logistics.minCompanyChapter, 4);
  });

  test('Daily Challenge bank includes logistics tasks', () async {
    final daily = await repository.loadDailyChallenges();

    expect(
      daily.where((item) => item.companyKey == 'logistics').length,
      greaterThanOrEqualTo(5),
    );
  });
}
