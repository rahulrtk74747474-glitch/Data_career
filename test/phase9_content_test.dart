import 'package:dataquest_analyst_career/repositories/content_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const repository = ContentRepository();

  test('final capstone loads with six weighted components', () async {
    final capstone = await repository.loadCapstone();

    expect(capstone.id, 'final-cross-company-capstone-001');
    expect(capstone.rubric.values.fold<int>(0, (a, b) => a + b), 100);
    expect(capstone.sqlExpectedRows, hasLength(5));
  });

  test('Interview Gauntlet mixes hiring-loop question types', () async {
    final rounds = await repository.loadInterviewRounds();
    final gauntlet = rounds.singleWhere(
      (round) => round.key == 'job_readiness_gauntlet',
    );

    expect(gauntlet.companyKey, 'logistics');
    expect(gauntlet.minCompanyChapter, 4);
    expect(gauntlet.durationSeconds, 900);
    expect(
      gauntlet.questions.map((item) => item.answerType).toSet(),
      containsAll({'sql_result', 'choice', 'rubric'}),
    );
    expect(gauntlet.questions.length, greaterThanOrEqualTo(6));
  });
}
